#import "../../InstagramHeaders.h"
#import "../../Manager.h"

%hook IGDSSegmentedPillBarView
- (void)didMoveToWindow {
    %orig;

    if ([[self delegate] isKindOfClass:%c(IGSearchTypeaheadNavigationHeaderView)]) {
        if ([SCIManager getPref:@"hide_trending_searches"]) {
            NSLog(@"[SCInsta] Hiding trending searches");

            [self removeFromSuperview];
        }
    }
}
%end