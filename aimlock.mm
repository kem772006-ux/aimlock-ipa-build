#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    UIWindowScene *ws = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:ws];
    
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    
    // Label HIEN NGAY
    UILabel *l = [[UILabel alloc] init];
    l.frame = CGRectMake(20, 120, ws.coordinateSpace.bounds.size.width-40, 500);
    l.text = @"🎯 AIMLOCK\n\nTrang thai: Dang tim game...\n\n⚠️ Hay mo GAME truoc\nroi moi mo app nay!\n\nHo tro: PUBG, CODM, Free Fire";
    l.textColor = [UIColor orangeColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 15;
    l.font = [UIFont boldSystemFontOfSize:16];
    [vc.view addSubview:l];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    // Delay 1 giay roi tim game
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self timGame:l];
    });
}

- (void)timGame:(UILabel *)label {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int m[4]={CTL_KERN,KERN_PROC,KERN_PROC_ALL,0};
        size_t z; sysctl(m,4,NULL,&z,NULL,0);
        struct kinfo_proc *p=(struct kinfo_proc*)malloc(z);
        sysctl(m,4,p,&z,NULL,0);
        pid_t g=-1;
        NSArray *n=@[@"PUBGM",@"ShadowTrackerExtra",@"codm",@"freefire",@"bgmi"];
        for(size_t i=0;i<z/sizeof(*p);i++){
            NSString *s=[NSString stringWithUTF8String:p[i].kp_proc.p_comm];
            for(NSString *x in n){if([s localizedCaseInsensitiveContainsString:x]){g=p[i].kp_proc.p_pid;break;}}
            if(g!=-1)break;
        }
        free(p);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(g==-1){
                label.text = @"❌ KHONG TIM THAY GAME!\n\nHuong dan:\n1. MO GAME TRUOC\n2. VAO TRAN DAU\n3. HOME -> MO APP NAY\n\nGame ho tro: PUBG, CODM, Free Fire, BGMI";
                label.textColor = [UIColor redColor];
            } else {
                mach_port_t t;
                if(task_for_pid(mach_task_self(),g,&t)==KERN_SUCCESS){
                    label.text = [NSString stringWithFormat:@"✅ DA KET NOI GAME!\nPID: %d\nBase: OK\n\nQUAY LAI GAME NGAY!\nAIMLOCK DANG CHAY...", g];
                    label.textColor = [UIColor greenColor];
                } else {
                    label.text = @"❌ THIEU QUYEN TRUY CAP!\n\nESIGN KHONG DU QUYEN.\nCAN TROLLSTORE!\n\nCai TrollStore tu:\njailbreaks.app";
                    label.textColor = [UIColor redColor];
                }
            }
        });
    });
}

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default" sessionRole:connectingSceneSession.role];
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
