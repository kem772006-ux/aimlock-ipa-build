#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    
    // Tao man hinh don gian
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0];
    
    // Title
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, self.window.bounds.size.width-40, 40)];
    title.text = @"AIMLOCK";
    title.textColor = [UIColor orangeColor];
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:title];
    
    // Status
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 150, self.window.bounds.size.width-40, 300)];
    status.text = @"Dang tim game...\n\n1. Mo game truoc\n2. Vao tran dau\n3. Home -> Mo app nay\n4. Quay lai game";
    status.textColor = [UIColor whiteColor];
    status.font = [UIFont systemFontOfSize:16];
    status.textAlignment = NSTextAlignmentCenter;
    status.numberOfLines = 10;
    status.tag = 100;
    [vc.view addSubview:status];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    // Tim game trong background
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self findGame:status];
    });
    
    return YES;
}

- (void)findGame:(UILabel *)status {
    // Tim process
    int m[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t z;
    sysctl(m, 4, NULL, &z, NULL, 0);
    struct kinfo_proc *p = (struct kinfo_proc*)malloc(z);
    sysctl(m, 4, p, &z, NULL, 0);
    
    pid_t gamePid = -1;
    NSArray *names = @[@"PUBGM",@"ShadowTrackerExtra",@"codm",@"freefire",@"bgmi"];
    
    for(size_t i = 0; i < z/sizeof(*p); i++) {
        NSString *n = [NSString stringWithUTF8String:p[i].kp_proc.p_comm];
        for(NSString *g in names) {
            if([n localizedCaseInsensitiveContainsString:g]) {
                gamePid = p[i].kp_proc.p_pid;
                break;
            }
        }
        if(gamePid != -1) break;
    }
    free(p);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(gamePid == -1) {
            status.text = @"❌ KHONG TIM THAY GAME!\nHay mo game truoc.\n\nHo tro: PUBG, CODM, Free Fire";
            status.textColor = [UIColor redColor];
        } else {
            mach_port_t task;
            if(task_for_pid(mach_task_self(), gamePid, &task) == KERN_SUCCESS) {
                status.text = [NSString stringWithFormat:@"✅ DA KET NOI GAME!\nPID: %d\n\nQUAY LAI GAME NGAY!", gamePid];
                status.textColor = [UIColor greenColor];
            } else {
                status.text = @"❌ CAN TROLLSTORE!\nESign khong du quyen.\nHay cai qua TrollStore.";
                status.textColor = [UIColor redColor];
            }
        }
    });
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
