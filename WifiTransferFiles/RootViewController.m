//
//  RootViewController.m
//  WifiTransferFiles
//
//  Created by 张丁豪 on 2017/5/5.
//  Copyright © 2017年 zhangdinghao. All rights reserved.
//

#import "RootViewController.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "MyHTTPConnection.h"
#import "DHIPAdress.h"
#import "CustomAlertView.h"

@interface RootViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    HTTPServer *httpServer;
}

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *dataArr;



@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Wifi Transfer Files";
    [self createAddFileBtn];
    self.view.backgroundColor = [UIColor whiteColor];
    [self createTableView];
    [self readLocalData];
}

- (void)readLocalData
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 在这里获取应用程序Documents文件夹里的文件及文件夹列表
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    self.dataArr = [fileManager contentsOfDirectoryAtPath:documentDir error:nil];
    
    NSLog(@"fileList == %@",self.dataArr);
    [self.tableView reloadData];
}

- (void)createTableView
{
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)createAddFileBtn
{
    
    UIButton *addbtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [addbtn setTitle:@"+" forState:UIControlStateNormal];
    [addbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [addbtn addTarget:self action:@selector(addBtnEvent) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightCunstomButtonView = [[UIBarButtonItem alloc] initWithCustomView:addbtn];
    self.navigationItem.rightBarButtonItem = rightCunstomButtonView;
}

- (void)addBtnEvent
{
    
    httpServer = [[HTTPServer alloc] init];
    [httpServer setType:@"_http._tcp."];
    // webPath是server搜寻HTML等文件的路径
    NSString *webPath = [[NSBundle mainBundle] resourcePath];
    [httpServer setDocumentRoot:webPath];
    [httpServer setConnectionClass:[MyHTTPConnection class]];
    NSError *err;
    NSString *IPAdress = [DHIPAdress deviceIPAdress];
    
    if ([httpServer start:&err] && [httpServer isRunning]) {
        NSLog(@"http://%@:%hu",IPAdress,[httpServer listeningPort]);
    }else{
        NSLog(@"%@",err);
    }
    
    NSString *uploadDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"文件地址：%@",uploadDirPath);
    
    NSString *str = [NSString stringWithFormat:@"http://%@:%hu",IPAdress,[httpServer listeningPort]];
    NSString *msg = [NSString stringWithFormat:@"请在电脑浏览器中输入以下地址：\n%@\n注意：电脑和手机要保持在同一局域网,并在文件传输结束后点击关闭按钮",str];
    
    [CustomAlertView showOneButtonWithTitle:@"提示" Message:msg ButtonType:CustomAlertViewButtonTypeDefault ButtonTitle:@"关闭" Click:^{
        
        [httpServer stop];
        [self readLocalData];
    }];
}

#pragma mark --
#pragma mark -- TableViewDele & DataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 55;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *homeTwoCell = @"HomeThreeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:homeTwoCell];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:homeTwoCell];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.dataArr[indexPath.row];
    return cell;
}



@end
