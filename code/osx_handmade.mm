#import <Cocoa/Cocoa.h>

#include <sys/mman.h>

#define internal static
#define local_persist static
#define global_variable static

typedef int8_t int8;
typedef int16_t int16;
typedef int32_t int32;
typedef int64_t int64;

typedef uint8_t uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef uint64_t uint64;

struct osx_offscreen_buffer {
    CGColorSpaceRef ColorSpace;
    CGContextRef Context;
    void *Memory;
    int Width;
    int Height;
    int Pitch;
};

global_variable bool GlobalRunning;
global_variable osx_offscreen_buffer GlobalBackBuffer;

internal void
RenderWeirdGradient(osx_offscreen_buffer *Buffer,
                    int BlueOffset, int GreenOffset) {
    uint8 *Row = (uint8 *) Buffer->Memory;
    for (int Y = 0; Y < Buffer->Height; ++Y) {
        uint32 *Pixel = (uint32 *) Row;
        for (int X = 0; X < Buffer->Width; ++X) {
            uint8 Blue = (X + BlueOffset);
            uint8 Green = (Y + GreenOffset);
            *Pixel++ = ((Green << 8) | (Blue << 16));
        }
        Row += Buffer->Pitch;
    }
}

internal void
OSXResizeGraphicsContext(osx_offscreen_buffer *Buffer, int Width, int Height) {
    int BytesPerPixel = 4;

    if (Buffer->Memory) {
        CGContextRelease(Buffer->Context);
        int BitmapMemorySize = Buffer->Width * Buffer->Height * BytesPerPixel;
        munmap(Buffer->Memory, BitmapMemorySize);
    } else {
        Buffer->ColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    }

    Buffer->Width = Width;
    Buffer->Height = Height;

    int BitmapMemorySize = Buffer->Width * Buffer->Height * BytesPerPixel;
    Buffer->Memory = mmap(0, BitmapMemorySize, PROT_READ | PROT_WRITE,
                          MAP_PRIVATE | MAP_ANON, -1, 0);
    Buffer->Context = CGBitmapContextCreate(Buffer->Memory,
                                            Buffer->Width, Buffer->Height, 8,
                                            Buffer->Width * BytesPerPixel,
                                            Buffer->ColorSpace,
                                            kCGImageAlphaNoneSkipLast);
    Buffer->Pitch = Buffer->Width * BytesPerPixel;
    // TODO(coeuvre): Probably clear this to black.
}

internal void
OSXDisplayBufferInWindow(CGContextRef Context, int WindowWidth, int WindowHeight,
                         osx_offscreen_buffer *Buffer) {
    CGImageRef Image = CGBitmapContextCreateImage(Buffer->Context);
    CGContextDrawImage(Context, CGRectMake(0, 0, WindowWidth, WindowHeight), Image);
    CGImageRelease(Image);
}

@interface HandmadeView : NSView
@end

@implementation HandmadeView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    CGContextRef Context = (CGContextRef) [[NSGraphicsContext currentContext]
                                           graphicsPort];
    OSXDisplayBufferInWindow(Context, self.bounds.size.width, self.bounds.size.height,
                             &GlobalBackBuffer);
}

@end

@interface HandmadeWindowDelegate : NSObject<NSWindowDelegate>
@end

@implementation HandmadeWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
    GlobalRunning = false;
    return NO;
}

@end

@interface HandmadeAppDelegate : NSObject<NSApplicationDelegate>
@end


@implementation HandmadeAppDelegate

- (void)applicationDidFinishLaunching:(id)sender
{
    printf("applicationDidFinishLaunching:\n");

    [NSApp stop:nil];

    // Send an empty event
    NSEvent *event = [NSEvent otherEventWithType:NSApplicationDefined
                              location:NSMakePoint(0, 0)
                              modifierFlags:NSDeviceIndependentModifierFlagsMask
                              timestamp:0.0
                              windowNumber:0
                              context:0
                              subtype:NSWindowExposedEventType
                              data1:0
                              data2:0];
    [NSApp postEvent:event atStart:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    printf("applicationDidBecomeActive:\n");
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    printf("applicationWillResignActive:\n");
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    GlobalRunning = false;
    return NSTerminateCancel;
}

@end

internal void
OSXCreateMainMenu(NSApplication *app) {
    NSMenu* menubar = [NSMenu new];

    NSMenuItem* appMenuItem = [NSMenuItem new];
    [menubar addItem:appMenuItem];

    [app setMainMenu:menubar];

    NSMenu* appMenu = [NSMenu new];

    //NSString* appName = [[NSProcessInfo processInfo] processName];
    NSString* appName = @"Handmade Hero";

    NSString* quitTitle = [@"Quit " stringByAppendingString:appName];
    NSMenuItem* quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                   action:@selector(terminate:)
                                                   keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];
}


int main() {
    [[NSAutoreleasePool alloc] init];

    OSXResizeGraphicsContext(&GlobalBackBuffer, 1280, 720);

    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    [app setDelegate: [HandmadeAppDelegate new]];

    OSXCreateMainMenu(app);

    NSRect contentRect = NSMakeRect(0, 0, 800, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:contentRect
                                         styleMask:NSTitledWindowMask |
                                                   NSClosableWindowMask |
                                                   NSMiniaturizableWindowMask |
                                                   NSResizableWindowMask
                                         backing:NSBackingStoreBuffered
                                         defer:NO];
    [window setDelegate:[HandmadeWindowDelegate new]];
    [window setTitle:@"Handmade Hero"];
    [window center];

    HandmadeView *view = [HandmadeView new];
    [view setFrame:[window frame]];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [window setContentView:view];

    [app activateIgnoringOtherApps:YES];
    [window makeKeyAndOrderFront:nil];

    // NOTE(coeuvre): Let the OSX do some initial things.
    // In the HandmadeAppDelegate, we will stop the inner loop.
    [app run];

    int XOffset = 0;
    int YOffset = 0;

    GlobalRunning = true;
    while (GlobalRunning) {
        NSEvent *event;
        while ((event = [NSApp nextEventMatchingMask:NSAnyEventMask
                               untilDate:nil
                               inMode:NSDefaultRunLoopMode
                               dequeue:YES])) {
            [NSApp sendEvent:event];
        }

        RenderWeirdGradient(&GlobalBackBuffer, XOffset, YOffset);

        [view display];

        ++XOffset;
        YOffset += 2;
    }

    return 0;
}
