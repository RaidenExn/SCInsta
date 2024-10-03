#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SCIManager : NSObject

+ (BOOL)getPref:(NSString *)key;

+ (void)showSaveVC:(id)item;
+ (void)cleanCache;
+ (NSString *)getDownloadingPersent:(float)per;

@end