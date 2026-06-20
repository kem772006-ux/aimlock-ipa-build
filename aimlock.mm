// aimlock.mm
// Исправленная версия: только AppDelegate, немедленный UI, поиск через sysctl
// Компиляция: clang++ -arch arm64 -isysroot $(xcrun --sdk iphoneos --show-sdk-path) -framework UIKit -framework Foundation -mios-version-min=12.0 -o aimlock aimlock.mm

#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UILabel *statusLabel;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 1. Создаём окно немедленно, чтобы избежать чёрного экрана
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    
    // 2. Статусная метка
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.window.bounds.size.width - 40, 400)];
    self.statusLabel.text = @"⏳ AIMLOCK\n\nĐang khởi động...\nVui lòng đợi...";
    self.statusLabel.textColor = [UIColor orangeColor];
    self.statusLabel.font = [UIFont boldSystemFontOfSize:16];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 12;
    [vc.view addSubview:self.statusLabel];
    
    // 3. Кнопка "Thử lại"
    UIButton *retryBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    retryBtn.frame = CGRectMake(60, 520, self.window.bounds.size.width - 120, 50);
    [retryBtn setTitle:@"THỬ LẠI" forState:UIControlStateNormal];
    [retryBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    retryBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.0 alpha:1.0];
    retryBtn.layer.cornerRadius = 10;
    [retryBtn addTarget:self action:@selector(startFindGame) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:retryBtn];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    // 4. Запускаем поиск игры с задержкой 1 сек (dispatch_after вместо performSelector)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self startFindGame];
    });
    
    return YES;
}

- (void)startFindGame {
    self.statusLabel.text = @"🔍 Đang tìm game...\n\nĐang quét tiến trình...";
    self.statusLabel.textColor = [UIColor orangeColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        pid_t foundPid = -1;
        
        // 5. Используем sysctl KERN_PROC_ALL (без proc_name)
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
                        [lowerName containsString:@"ffm"]) { {
                        break;
                    }
                }
            }
            free(procList);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (foundPid == -1) {
                self.statusLabel.text = @"❌ KHÔNG TÌM THẤY GAME!\n\nHướng dẫn:\n1. MỞ GAME TRƯỚC\n2. VÀO TRẬN ĐẤU (có súng)\n3. Home → Mở app này\n4. Nhấn THỬ LẠI\n\nGame hỗ trợ:\nPUBG, CODM, Free Fire";
                self.statusLabel.textColor = [UIColor redColor];
            } else {
                mach_port_t taskPort = MACH_PORT_NULL;
                kern_return_t kr = task_for_pid(mach_task_self(), foundPid, &taskPort);
                
                if (kr == KERN_SUCCESS) {
                    self.statusLabel.text = [NSString stringWithFormat:@"✅ KẾT NỐI THÀNH CÔNG!\n\nPID: %d\nTask: 0x%x\n\nQUAY LẠI GAME NGAY!\nAimlock đang hoạt động.", foundPid, taskPort];
                    self.statusLabel.textColor = [UIColor greenColor];
                } else {
                    self.statusLabel.text = [NSString stringWithFormat:@"❌ THIẾU QUYỀN!\n\nTìm thấy game (PID:%d)\nnhưng KHÔNG ĐỦ QUYỀN truy cập.\n\nESIGN KHÔNG ĐỦ QUYỀN.\nCẦN TROLLSTORE!\n\nTải TrollStore:\njailbreaks.app", foundPid];
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
