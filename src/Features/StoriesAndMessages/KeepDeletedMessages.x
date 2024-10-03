#import "../../InstagramHeaders.h"
#import "../../Manager.h"

%hook IGDirectRealtimeIrisThreadDelta
+ (id)removeItemWithMessageId:(id)arg1 {
    if ([SCIManager getPref:@"keep_deleted_message"]) {
        arg1 = NULL;
    }

    return %orig(arg1);
}
%end

%hook IGDirectMessageUpdate
+ (id)removeMessageWithMessageId:(id)arg1{
    if ([SCIManager getPref:@"keep_deleted_message"]) {
        arg1 = NULL;
    }
    
    return %orig(arg1);
}
%end