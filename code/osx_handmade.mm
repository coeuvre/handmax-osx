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

global_variable bool Running;

global_variable CGColorSpaceRef ColorSpace;
global_variable CGContextRef BitmapContext;
global_variable void *BitmapMemory;
global_variable int BitmapWidth;
global_variable int BitmapHeight;
global_variable int BytesPerPixel = 4;

internal void
RenderWeirdGradient(int BlueOffset, int GreenOffset) {
    int Width = BitmapWidth;
    int Pitch = Width*BytesPerPixel;
    uint8 *Row = (uint8 *)BitmapMemory;
    for (int Y = 0; Y < BitmapHeight; ++Y) {
        uint32 *Pixel = (uint32 *) Row;
        for (int X = 0; X < BitmapWidth; ++X) {
            uint8 Blue = (X + BlueOffset);
            uint8 Green = (Y + GreenOffset);
            *Pixel++ = ((Green << 8) | (Blue << 16));
        }
        Row += Pitch;
    }
}

internal void
OSXResizeGraphicsContext(int Width, int Height) {
    if (BitmapContext) {
        CGContextRelease(BitmapContext);
        int BitmapMemorySize = BitmapWidth * BitmapHeight * BytesPerPixel;
        munmap(BitmapMemory, BitmapMemorySize);
    } else {
        ColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    }

    BitmapWidth = Width;
    BitmapHeight = Height;

    int BitmapMemorySize = BitmapWidth * BitmapHeight * BytesPerPixel;
    BitmapMemory = mmap(0, BitmapMemorySize, PROT_READ | PROT_WRITE,
                        MAP_PRIVATE | MAP_ANON, -1, 0);
    BitmapContext = CGBitmapContextCreate(BitmapMemory, Width, Height, 8,
                                          BitmapWidth * BytesPerPixel,
                                          ColorSpace,
                                          kCGImageAlphaNoneSkipLast);
}

internal void
OSXUpdateWindow(CGContextRef Context, NSRect Bounds) {
    if (!BitmapContext) {
        OSXResizeGraphicsContext(Bounds.size.width, Bounds.size.height);
    }

    CGImageRef Image = CGBitmapContextCreateImage(BitmapContext);
    CGContextDrawImage(Context, Bounds, Image);
    CGImageRelease(Image);
}

@interface HandmadeView : NSView
@end

@implementation HandmadeView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    CGContextRef Context = (CGContextRef) [[NSGraphicsContext currentContext]
                                           graphicsPort];
    OSXUpdateWindow(Context, self.bounds);
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
    [super resizeWithOldSuperviewSize:oldBoundsSize];

    OSXResizeGraphicsContext(self.bounds.size.width, self.bounds.size.height);
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
    Running = false;
    return NSTerminateCancel;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
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

    Running = true;
    while (Running) {
        NSEvent *event;
        while ((event = [NSApp nextEventMatchingMask:NSAnyEventMask
                               untilDate:nil
                               inMode:NSDefaultRunLoopMode
                               dequeue:YES])) {
            [NSApp sendEvent:event];
        }

        RenderWeirdGradient(XOffset, YOffset);

        [view display];

        ++XOffset;
        YOffset += 2;
    }

    return 0;
}
