#import "../../InstagramHeaders.h"
#import "../../Manager.h"

// Channels dms tab (header)
%hook IGDirectInboxHeaderSectionController
- (id)viewModel {
    if ([[%orig title] isEqualToString:@"Suggested"]) {

        if ([SCIManager getPref:@"no_suggested_chats"]) {
            NSLog(@"[SCInsta] Hiding suggested chats (header: channels tab)");

            return nil;
        }

    }

    return %orig;
}
%end

// Messaages dms tab (suggestions header)
%hook IGDirectInboxListAdapterDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSMutableArray *newObjs = [%orig mutableCopy];

    [newObjs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        // Section header
        if ([obj isKindOfClass:%c(IGDirectInboxHeaderCellViewModel)]) {
            
            // "Suggestions" header
            if ([[obj title] isEqualToString:@"Suggestions"]) {
                if ([SCIManager getPref:@"hide_meta_ai"]) {
                    NSLog(@"[SCInsta] Hiding suggested chats (header: messages tab)");

                    [newObjs removeObjectAtIndex:idx];
                }
            }

        }

        // Suggested recipients
        if ([obj isKindOfClass:%c(IGDirectInboxSuggestedThreadCellViewModel)]) {
            if ([SCIManager getPref:@"hide_meta_ai"]) {
                NSLog(@"[SCInsta] Hiding suggested chats (recipients: channels tab)");

                [newObjs removeObjectAtIndex:idx];
            }
        }

    }];

    return [newObjs copy];
}
%end
