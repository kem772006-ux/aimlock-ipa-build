#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UILabel *statusLabel;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.window.bounds.size.width - 40, 400)];
    self.statusLabel.text = @"⏳ AIMLOCK\n\nDang khoi dong...\nVui long doi...";
    self.statusLabel.textColor = [UIColor orangeColor];
    self.statusLabel.font = [UIFont boldSystemFontOfSize:16];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 12;
    [vc.view addSubview:self.statusLabel];
    
    UIButton *retryBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    retryBtn.frame = CGRectMake(60, 520, self.window.bounds.size.width - 120, 50);
    [retryBtn setTitle:@"THU LAI" forState:UIControlStateNormal];
    [retryBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    retryBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.0 alpha:1.0];
    retryBtn.layer.cornerRadius = 10;
    [retryBtn addTarget:self action:@selector(startFindGame) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:retryBtn];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    [self performSelector:@selector(startFindGame) withObject:nil afterDelay:0.5];
    
    return YES;
}

- (void)startFindGame {
    self.statusLabel.text = @"🔍 Dang tim game...\n\nQuet process...";
    self.statusLabel.textColor = [UIColor orangeColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        pid_t foundPid = -1;
        
        int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
        size_t size = 0;
        
        if (sysctl(mib, 4, NULL, &size, NULL, 0) == 0) {
            struct kinfo_proc *procList = (struct kinfo_proc *)malloc(size);
            if (sysctl(mib, 4, procList, &size, NULL, 0) == 0) {
                size_t count = size / sizeof(struct kinfo_proc);
                for (size_t i = 0; i < count; i++) {
                    NSString *name = [NSString stringWithUTF8String:procList[i].kp_proc.p_comm];
                    if ([name localizedCaseInsensitiveContainsString:@"PUBGM"] ||
                        [name localizedCaseInsensitiveContainsString:@"ShadowTrackerExtra"] ||
                        [name localizedCaseInsensitiveContainsString:@"codm"] ||
                        [name localizedCaseInsensitiveContainsString:@"freefire"] ||
                        [name localizedCaseInsensitiveContainsString:@"bgmi"]) {
                        foundPid = procList[i].kp_proc.p_pid;
                        break;
                    }
                }
            }
            free(procList);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (foundPid == -1) {
                self.statusLabel.text = @"❌ KHONG TIM THAY GAME!\n\nHuong dan:\n1. MO GAME TRUOC\n2. VAO TRAN DAU (co sung)\n3. HOME -> MO APP NAY\n4. Nhan THU LAI\n\nGame ho tro:\nPUBG, CODM, Free Fire";
                self.statusLabel.textColor = [UIColor redColor];
            } else {
                mach_port_t taskPort = MACH_PORT_NULL;
                kern_return_t kr = task_for_pid(mach_task_self(), foundPid, &taskPort);
                if (kr == KERN_SUCCESS) {
                    self.statusLabel.text = [NSString stringWithFormat:@"✅ KET NOI THANH CONG!\n\nPID: %d\nTask: 0x%x\n\nQUAY LAI GAME NGAY!\nAimlock dang hoat dong.", foundPid, taskPort];
                    self.statusLabel.textColor = [UIColor greenColor];
                } else {
                    self.statusLabel.text = [NSString stringWithFormat:@"❌ THIEU QUYEN!\n\nTim thay game (PID:%d)\nnhung KHONG DU QUYEN truy cap.\n\nESIGN KHONG DU QUYEN.\nCAN TROLLSTORE!\n\nTai TrollStore:\njailbreaks.app", foundPid];
                    self.statusLabel.textColor = [UIColor redColor];
                }
            }
        });
    });
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return YES;
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
