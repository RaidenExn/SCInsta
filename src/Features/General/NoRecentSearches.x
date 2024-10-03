#import "../../InstagramHeaders.h"
#import "../../Manager.h"

// Disable logging of searches at server-side
%hook IGSearchEntityRouter
- (id)initWithUserSession:(id)arg1 analyticsModule:(id)arg2 shouldAddToRecents:(BOOL)shouldAddToRecents {
    if ([SCIManager getPref:@"no_recent_searches"]) {
        NSLog(@"[SCInsta] Disabling recent searches");

        shouldAddToRecents = false;
    }
    
    return %orig(arg1, arg2, shouldAddToRecents);
}
%end

// Most in-app search bars
%hook IGRecentSearchStore
- (id)initWithDiskManager:(id)arg1 recentSearchStoreConfiguration:(id)arg2 {
    if ([SCIManager getPref:@"no_recent_searches"]) {
        NSLog(@"[SCInsta] Disabling recent searches");

        return nil;
    }

    return %orig;
}
- (BOOL)addItem:(id)arg1 {
    if ([SCIManager getPref:@"no_recent_searches"]) {
        NSLog(@"[SCInsta] Disabling recent searches");

        return nil;
    }

    return %orig;
}
%end

// Recent dm message recipients search bar
%hook IGDirectRecipientRecentSearchStorage
- (id)initWithDiskManager:(id)arg1 directCache:(id)arg2 userStore:(id)arg3 currentUser:(id)arg4 featureSets:(id)arg5 {
    if ([SCIManager getPref:@"no_recent_searches"]) {
        NSLog(@"[SCInsta] Disabling recent searches");

        return nil;
    }

    return %orig;
}
%end