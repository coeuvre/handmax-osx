#import <Cocoa/Cocoa.h>

@interface HandmadeView : NSView
@end

@implementation HandmadeView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    static NSColor *Operation = [NSColor whiteColor];
    [Operation set];
    NSRectFill(dirtyRect);
    if (Operation == [NSColor whiteColor]) {
        Operation = [NSColor blackColor];
    } else {
        Operation = [NSColor whiteColor];
    }
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
    printf("resizeWithOldSuperviewSize:\n");
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

void OSXCreateMainMenu(NSApplication *app)
{
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
