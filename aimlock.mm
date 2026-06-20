#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

static mach_port_t task = MACH_PORT_NULL;
static uint64_t base = 0;
static pid_t pid = 0;

@interface ViewController : UIViewController
@property (strong, nonatomic) UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    
    // Title
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 50)];
    title.text = @"🎯 AIMLOCK";
    title.textColor = [UIColor orangeColor];
    title.font = [UIFont boldSystemFontOfSize:28];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    
    // Status
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.bounds.size.width, 100)];
    self.statusLabel.text = @"⏳ Dang tim game...";
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.font = [UIFont systemFontOfSize:16];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 5;
    [self.view addSubview:self.statusLabel];
    
    // Button
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(50, 350, self.view.bounds.size.width-100, 50);
    [btn setTitle:@"MO GAME ROI QUAY LAI DAY" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor orangeColor];
    btn.layer.cornerRadius = 10;
    [self.view addSubview:btn];
    
    // Info
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(0, 420, self.view.bounds.size.width, 200)];
    info.text = @"1. MO GAME TRUOC\n2. VAO TRAN DAU\n3. HOME -> MO APP NAY\n4. DOI THONG BAO OK\n5. QUAY LAI GAME";
    info.textColor = [UIColor grayColor];
    info.font = [UIFont systemFontOfSize:14];
    info.textAlignment = NSTextAlignmentCenter;
    info.numberOfLines = 6;
    [self.view addSubview:info];
    
    [self findAndAttach];
}

- (void)findAndAttach {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Tim game
        int m[4]={CTL_KERN,KERN_PROC,KERN_PROC_ALL,0};
        size_t z; sysctl(m,4,NULL,&z,NULL,0);
        struct kinfo_proc *p=(struct kinfo_proc*)malloc(z);
        sysctl(m,4,p,&z,NULL,0);
        NSArray *n=@[@"PUBGM",@"ShadowTrackerExtra",@"codm",@"freefire",@"bgmi"];
        for(size_t i=0;i<z/sizeof(*p);i++) {
            NSString *s=[NSString stringWithUTF8String:p[i].kp_proc.p_comm];
            for(NSString *g in n) {
                if([s localizedCaseInsensitiveContainsString:g]){pid=p[i].kp_proc.p_pid;break;}
            }
            if(pid!=-1)break;
        }
        free(p);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(pid==-1) {
                self.statusLabel.text = @"❌ KHONG TIM THAY GAME!\nHay mo game truoc.";
            } else {
                if(task_for_pid(mach_task_self(),pid,&task)==KERN_SUCCESS) {
                    // Tim base
                    vm_address_t a=0; vm_size_t s=0;
                    while(1) {
                        mach_msg_type_number_t c=VM_REGION_BASIC_INFO_COUNT_64;
                        struct vm_region_basic_info_64 inf; mach_port_t o;
                        if(vm_region_64(task,&a,&s,VM_REGION_BASIC_INFO_64,(vm_region_info_t)&inf,&c,&o)!=KERN_SUCCESS)break;
                        if(inf.protection&VM_PROT_READ) {
                            char b[512]={0}; vm_size_t rs=511;
                            vm_read_overwrite(task,a,rs,(vm_address_t)b,&rs);
                            if([[NSString stringWithUTF8String:b] containsString:@"UnityFramework"]){base=a;break;}
                        }
                        a+=s;
                        if(a>0x300000000)break;
                    }
                    
                    if(base) {
                        self.statusLabel.text = [NSString stringWithFormat:@"✅ AIMLOCK SAN SANG!\nPID: %d\nBase: 0x%llx\n\nQUAY LAI GAME NGAY!", pid, base];
                    } else {
                        self.statusLabel.text = [NSString stringWithFormat:@"⚠️ Da ket noi game (PID:%d)\nNhung khong tim thay module", pid];
                    }
                } else {
                    self.statusLabel.text = @"❌ KHONG CO QUYEN!\nCan TrollStore de cap quyen";
                }
            }
        });
    });
}

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[ViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
