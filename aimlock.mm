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
    self.statusLabel.text = @"AIMLOCK\n\nDang khoi dong...";
    self.statusLabel.textColor = [UIColor orangeColor];
    self.statusLabel.font = [UIFont boldSystemFontOfSize:16];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 12;
    [vc.view addSubview:self.statusLabel];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(60, 520, self.window.bounds.size.width - 120, 50);
    [btn setTitle:@"THU LAI" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.0 alpha:1.0];
    btn.layer.cornerRadius = 10;
    [btn addTarget:self action:@selector(startFindGame) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:btn];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self startFindGame];
    });
    
    return YES;
}

- (void)startFindGame {
    self.statusLabel.text = @"Dang tim game...";
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
                    NSString *lowerName = [name lowercaseString];
                    if ([lowerName containsString:@"freefire"] ||
                        [lowerName containsString:@"free fire"] ||
                        [lowerName containsString:@"garena"] ||
                        [lowerName containsString:@"com.dts.freefire"] ||
                        [lowerName containsString:@"ffmax"] ||
                        [lowerName containsString:@"ffm"]) {
                        foundPid = procList[i].kp_proc.p_pid;
                        break;
                    }
                }
            }
            free(procList);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (foundPid == -1) {
                self.statusLabel.text = @"KHONG TIM THAY GAME!\n\n1. Mo Free Fire truoc\n2. Vao tran dau\n3. Home -> Mo app nay\n4. Nhan THU LAI";
                self.statusLabel.textColor = [UIColor redColor];
            } else {
                mach_port_t taskPort = MACH_PORT_NULL;
                kern_return_t kr = task_for_pid(mach_task_self(), foundPid, &taskPort);
                if (kr == KERN_SUCCESS) {
                    self.statusLabel.text = [NSString stringWithFormat:@"KET NOI THANH CONG!\nPID: %d\n\nQUAY LAI GAME!", foundPid];
                    self.statusLabel.textColor = [UIColor greenColor];
                } else {
                    self.statusLabel.text = [NSString stringWithFormat:@"THIEU QUYEN!\nPID: %d\n\nCAN TROLLSTORE!", foundPid];
                    self.statusLabel.textColor = [UIColor redColor];
                }
            }
        });
    });
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
