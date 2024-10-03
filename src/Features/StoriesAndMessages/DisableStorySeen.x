#import "../../InstagramHeaders.h"
#import "../../Manager.h"

%hook IGStorySeenStateUploader
- (id)initWithUserSessionPK:(id)arg1 networker:(id)arg2 {
    if ([SCIManager getPref:@"no_seen_receipt"]) {
        NSLog(@"[SCInsta] Prevented seen receipt from being sent");

        return nil;
    }
    
    return %orig;
}

- (id)networker {
    if ([SCIManager getPref:@"no_seen_receipt"]) {
        NSLog(@"[SCInsta] Prevented seen receipt from being sent");

        return nil;
    }
    
    return %orig;
}
%end