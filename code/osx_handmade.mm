#include <stdlib.h>

#import <Cocoa/Cocoa.h>

#define internal static
#define local_persist static
#define global_variable static

global_variable CGColorSpaceRef ColorSpace;
global_variable void *BitmapMemory;
global_variable CGContextRef BitmapContext;

internal void
OSXResizeGraphicsContext(int Width, int Height) {
    if (BitmapContext) {
        CGContextRelease(BitmapContext);
        free(BitmapMemory);
    } else {
        ColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    }

    int BytesPerRow = (Width * 4);
    int ByteCount = (BytesPerRow * Height);

    BitmapMemory = calloc(ByteCount, 1);
    BitmapContext = CGBitmapContextCreate(BitmapMemory, Width, Height, 8,
                                          BytesPerRow, ColorSpace,
                                          kCGImageAlphaPremultipliedLast);
}

internal void
OSXUpdateWindow(CGContextRef Context, int X, int Y, int Width, int Height) {
    if (!BitmapContext) {
        OSXResizeGraphicsContext(Width, Height);
    }

    CGRect BoundingBox = CGRectMake (X, Y, Width, Height);
    CGImageRef Image = CGBitmapContextCreateImage (BitmapContext);
    CGContextDrawImage(Context, BoundingBox, Image);
    CGImageRelease(Image);
}

@interface HandmadeView : NSView
@end

@implementation HandmadeView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    CGContextRef Context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
    OSXUpdateWindow(Context, dirtyRect.origin.x, dirtyRect.origin.y,
                    dirtyRect.size.width, dirtyRect.size.height);
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
    OSXResizeGraphicsContext(oldBoundsSize.width, oldBoundsSize.height);
}

@end

@interface HandmadeAppDelegate : NSObject<NSApplicationDelegate>
@end


@implementation HandmadeAppDelegate

- (void)applicationDidFinishLaunching:(id)sender
{
    printf("applicationDidFinishLaunching:\n");
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    printf("applicationDidBecomeActive:\n");
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    printf("applicationWillResignActive:\n");
}

- (void)applicationWillTerminate:(NSApplication*)sender
{
    printf("applicationWillTerminate:\n");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
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

    [app run];
    return 0;
}
