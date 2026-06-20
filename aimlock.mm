#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

static mach_port_t gTask = MACH_PORT_NULL;
static uint64_t gGameBase = 0;
static pid_t gGamePid = 0;
static BOOL gRunning = YES;

static uint64_t OFF_ENTITY_LIST = 0x1A5E4B0;
static uint64_t OFF_LOCAL_PLAYER = 0x1A2F8C8;
static uint64_t OFF_TEAM = 0x9C;
static uint64_t OFF_HEALTH = 0xA8;

uint64_t read64(uint64_t addr) {
    uint64_t v = 0;
    vm_size_t s = 8;
    vm_read_overwrite(gTask, (vm_address_t)addr, s, (vm_address_t)&v, &s);
    return v;
}
uint32_t read32(uint64_t addr) {
    uint32_t v = 0;
    vm_size_t s = 4;
    vm_read_overwrite(gTask, (vm_address_t)addr, s, (vm_address_t)&v, &s);
    return v;
}

pid_t findGame(void) {
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t sz;
    sysctl(mib, 4, NULL, &sz, NULL, 0);
    struct kinfo_proc *p = (struct kinfo_proc*)malloc(sz);
    sysctl(mib, 4, p, &sz, NULL, 0);
    pid_t r = -1;
    NSArray *names = @[@"PUBGM",@"ShadowTrackerExtra",@"codm",@"freefire",@"bgmi"];
    for(size_t i = 0; i < sz/sizeof(*p); i++) {
        NSString *n = [NSString stringWithUTF8String:p[i].kp_proc.p_comm];
        for(NSString *g in names) {
            if([n localizedCaseInsensitiveContainsString:g]) {
                r = p[i].kp_proc.p_pid;
                break;
            }
        }
        if(r != -1) break;
    }
    free(p);
    return r;
}

uint64_t findModuleBase(NSString *modName) {
    vm_address_t addr = 0;
    vm_size_t size = 0;
    while(1) {
        mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
        struct vm_region_basic_info_64 info;
        mach_port_t obj;
        kern_return_t kr = vm_region_64(gTask, &addr, &size, VM_REGION_BASIC_INFO_64,
                                         (vm_region_info_t)&info, &count, &obj);
        if(kr != KERN_SUCCESS) break;
        if(info.protection & VM_PROT_READ) {
            char buf[512] = {0};
            vm_size_t rs = 511;
            vm_read_overwrite(gTask, addr, rs, (vm_address_t)buf, &rs);
            NSString *s = [NSString stringWithUTF8String:buf];
            if([s containsString:modName]) return addr;
        }
        addr += size;
        if(addr > 0x300000000) break;
    }
    return 0;
}

@interface AimController : NSObject
+ (instancetype)shared;
- (BOOL)setup;
- (void)start;
@end

@implementation AimController
+ (instancetype)shared {
    static AimController *i = nil;
    static dispatch_once_t o;
    dispatch_once(&o, ^{ i = [[AimController alloc] init]; });
    return i;
}
- (BOOL)setup {
    gGamePid = findGame();
    if(gGamePid == -1) return NO;
    if(task_for_pid(mach_task_self(), gGamePid, &gTask) != KERN_SUCCESS) return NO;
    gGameBase = findModuleBase(@"UnityFramework");
    if(!gGameBase) gGameBase = findModuleBase(@"libil2cpp");
    if(!gGameBase) return NO;
    return YES;
}
- (void)start {
    gRunning = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while(gRunning) {
            usleep(4000);
        }
    });
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        AimController *c = [AimController shared];
        if([c setup]) {
            [c start];
            [[NSRunLoop currentRunLoop] run];
        }
    }
    return 0;
}
