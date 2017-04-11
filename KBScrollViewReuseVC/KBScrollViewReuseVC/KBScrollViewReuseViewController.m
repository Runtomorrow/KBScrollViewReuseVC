//
//  KBScrollViewReuseViewController.m
//  KBScrollViewReuseVC
//
//  Created by kobe on 2017/4/9.
//  Copyright © 2017年 kobe. All rights reserved.
//

#import "KBScrollViewReuseViewController.h"
#import "Masonry.h"
#import "KBBaseVC.h"

#define kTotalPages 10
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface KBScrollViewReuseViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIScrollView *bottomScrollView;

@property (nonatomic, strong) NSNumber *currentPage;
@property (nonatomic, strong) NSMutableArray *reusableViewControllers;
@property (nonatomic, strong) NSMutableArray *visibleViewControllers;
@end

@implementation KBScrollViewReuseViewController

- (UIView *)topView{
    if (!_topView) {
        _topView = [UIView new];
        _topView.backgroundColor = [UIColor orangeColor];
        _topView.frame = CGRectMake(0, 64, kScreenWidth, 40);
    }
    return _topView;
}

- (UIScrollView *)bottomScrollView{
    if (!_bottomScrollView) {
        _bottomScrollView = [UIScrollView new];
        _bottomScrollView.delegate = self;
        _bottomScrollView.showsVerticalScrollIndicator = NO;
        _bottomScrollView.bounces = NO;
        _bottomScrollView.pagingEnabled = YES;
        _bottomScrollView.frame = CGRectMake(0, 104, kScreenWidth, kScreenHeight-104);
        _bottomScrollView.contentSize = CGSizeMake(kScreenWidth*kTotalPages, kScreenHeight);
        _bottomScrollView.scrollEnabled = YES;
    }
    return _bottomScrollView;
}

- (NSMutableArray *)reusableViewControllers{
    if (!_reusableViewControllers) {
        _reusableViewControllers = [NSMutableArray array];
    }
    return _reusableViewControllers;
}

- (NSMutableArray *)visibleViewControllers{
    if (!_visibleViewControllers) {
        _visibleViewControllers = [NSMutableArray array];
    }
    return _visibleViewControllers;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomScrollView];
    [self loadPage:0];
}


- (void)loadPage:(NSInteger)page{
    
    //如果加载的是当前页面则直接返回
    if (self.currentPage && page == [self.currentPage integerValue]) {
        return;
    }
    
    self.currentPage = @(page);
    NSMutableArray *pagesToLoad = [@[@(page),@(page-1),@(page+1)] mutableCopy];
    NSMutableArray *vcToEnqueue = [NSMutableArray array];
    
    //计算需要加载的视图
    for (KBBaseVC *vc in self.visibleViewControllers) {
        if (!vc.page || ![pagesToLoad containsObject:vc.page]) {
            [vcToEnqueue addObject:vc];
        }else if (vc.page){
            [pagesToLoad removeObject:vc.page];
        }
    }
    
    //移除当期不需要显示的视图，并且放进缓存池里
    for (KBBaseVC *vc in vcToEnqueue) {
        [vc.view removeFromSuperview];
        [self.visibleViewControllers removeObject:vc];
        [self enqueueReusableViewController:vc];
    }
    
    //加载需要显示的视图
    for (NSNumber *page in pagesToLoad) {
        [self addViewControllerForPage:[page integerValue]];
    }
    
}

//放进缓存池中
- (void)enqueueReusableViewController:(KBBaseVC *)viewController{
    [self.reusableViewControllers addObject:viewController];
}


//从缓存池中获取控制器
- (KBBaseVC *)dequeueReusableViewController{
    static int numberOfInstance = 0;
    KBBaseVC *vc = [self.reusableViewControllers firstObject];
    if (vc) {
        [self.reusableViewControllers removeObject:vc];
    }else{
        vc = [KBBaseVC new];
        vc.numberOfInstance = numberOfInstance;
        numberOfInstance++;
        [vc willMoveToParentViewController:self];
        [self addChildViewController:vc];
        [vc didMoveToParentViewController:self];
    }
    return vc;
}


//加载需要显示的页面
- (void)addViewControllerForPage:(NSInteger)page{
    if (page < 0 || page >= kTotalPages) {
        return;
    }
    KBBaseVC *vc = [self dequeueReusableViewController];
    vc.page = @(page);
    vc.view.frame = CGRectMake(kScreenWidth*page, 0, kScreenWidth, kScreenHeight);
    [self.bottomScrollView addSubview:vc.view];
    [self.visibleViewControllers addObject:vc];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (scrollView == self.bottomScrollView) {
        NSInteger page = roundf(scrollView.contentOffset.x / scrollView.frame.size.width);
        page = MAX(page, 0);
        page = MIN(page, kTotalPages-1);
        [self loadPage:page];
    }
}


@end
