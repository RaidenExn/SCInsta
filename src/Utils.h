#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../modules/JGProgressHUD/JGProgressHUD.h"

@interface SCIUtils : NSObject

// Colours
+ (UIColor *)SCIColour_Primary;

// Errors
+ (NSError *)errorWithDescription:(NSString *)errorDesc;
+ (NSError *)errorWithDescription:(NSString *)errorDesc code:(NSInteger)errorCode;

+ (JGProgressHUD *)showErrorHUDWithDescription:(NSString *)errorDesc;
+ (JGProgressHUD *)showErrorHUDWithDescription:(NSString *)errorDesc dismissAfterDelay:(CGFloat)dismissDelay;

// Functions
+ (NSString *)IGVersionString;
+ (BOOL)isNotch;

+ (BOOL)showConfirmation:(void(^)(void))okHandler;
+ (void)prepareAlertPopoverIfNeeded:(UIAlertController*)alert inView:(UIView*)view;

@end