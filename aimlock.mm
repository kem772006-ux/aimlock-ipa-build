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
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, ws.coordinateSpace.bounds.size.width-40, 400)];
    l.text = @"AIMLOCK\n\nDang tim game...\n\n1. Mo game\n2. Vao tran\n3. Home -> App nay\n4. Quay game";
    l.textColor = [UIColor orangeColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 10;
    l.font = [UIFont boldSystemFontOfSize:18];
    l.tag = 99;
    [vc.view addSubview:l];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
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
            UILabel *lb = [self.window viewWithTag:99];
            if(g==-1){lb.text=@"❌ KHONG TIM THAY GAME";lb.textColor=[UIColor redColor];}
            else {
                mach_port_t t;
                if(task_for_pid(mach_task_self(),g,&t)==KERN_SUCCESS){
                    lb.text=[NSString stringWithFormat:@"✅ OK PID:%d\nQUAY LAI GAME",g];
                    lb.textColor=[UIColor greenColor];
                }else{
                    lb.text=@"❌ CAN TROLLSTORE\nESIGN KHONG DU QUYEN";
                    lb.textColor=[UIColor redColor];
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
