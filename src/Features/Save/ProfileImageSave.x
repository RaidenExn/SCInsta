#import "../../InstagramHeaders.h"
#import "../../Manager.h"
#import "../../Utils.h"

%hook IGProfilePicturePreviewViewController
%property (nonatomic, strong) JGProgressHUD *hud;
- (void)viewDidLoad {
    %orig;
    if ([SCIManager getPref:@"save_profile"]) {
        [self addHandleLongPress];
    }
}
%new - (void)addHandleLongPress {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.3;
    [self.view addGestureRecognizer:longPress];
}

%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"[SCInsta] Save pfp: Preparing alert");

        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"SCInsta Downloader" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        IGImageView *profilePictureView = [self valueForKey:@"_profilePictureView"];
        NSURL *url = profilePictureView.imageSpecifier.url;

        [alert addAction:[UIAlertAction actionWithTitle:@"Download HD Profile Picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            SCIDownload *dwManager = [[SCIDownload alloc] init];
            [dwManager downloadFileWithURL:url];
            [dwManager setDelegate:self];

            self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            self.hud.textLabel.text = @"Downloading";
            [self.hud showInView:topMostController().view];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [SCIUtils prepareAlertPopoverIfNeeded:alert inView:profilePictureView];
        
        NSLog(@"[SCInsta] Save pfp: Displaying alert");

        [self presentViewController:alert animated:YES completion:nil];
    }
}

%new - (void)downloadProgress:(float)progress {
    self.hud.detailTextLabel.text = [SCIManager getDownloadingPersent:progress];
}
%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *DocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *newFilePath = [[NSURL fileURLWithPath:DocPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", NSUUID.UUID.UUIDString]];
    [manager moveItemAtURL:filePath toURL:newFilePath error:nil];

    [self.hud dismiss];

    NSLog(@"[SCInsta] Save pfp: Displaying save dialog");

    [SCIManager showSaveVC:newFilePath];
}
%new - (void)downloadDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}
%end