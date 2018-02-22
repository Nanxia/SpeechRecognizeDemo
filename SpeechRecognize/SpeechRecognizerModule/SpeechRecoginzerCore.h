//                               .
//                                'hz.
//            .                  .DhB+
//          (-                   =B~=B'
//         <NB~                 -B+(<h+
//         zs=B-                =D(<(+h.
//        'D+~hs  ..            Ds(<<<D~
//        +B<((z(     ~<=szhzz=sB<(<<(h+
//        zh(<<+D' '+hNBBDzszzhh=(<<<(ss
//     . .h=(<<(s+=DBhs<~((((''((<<<<<=D'
//       ~D<<<<<<=s=(~~-.'<+(..~<<<(<<<B(
//       (h(<<<<<<~(+==(.-++<--zDDDz(((h+
//       =z(<<<<((sDDhBB+(<<(+ND=<+DB<~zs
//      .hs(<<<((hh('.'+Ns(<<Bs.   .hB(=h.
//      (B+(<<<(zD.     <B+~hz   ..  hz<D-  ~=+~-
//      =B<<<<(+D-       hz(B<       -B=h~ ~Bhs=hs.
//     .hD<<<<(sD.   .=( +h<D-    '=- zsz( == .-zN-
//     'Bz(<<<(=D'   (NB <h+D-  . (Nz =zz+ D-~DDz(
//     ~B=(<<<(+B~   '=< <h<D-    's( zss+<h.zs-   .
//     <B+<<<<<(hz       zs+Bs+(     .B==sz< D-
//     sB+<<<<<(+N+.    =D~sBBNh     sD(<DD' D(
//    .hh(<<<<<<(sND<'~zB<.'hBDh(.'~zD+(+Bh .h~
//    'Bz(<<<<<<<(+zDBBh-.  s='<zhhBh<((+Bs -D-
//    -Bz(<<<<<<<<-.-+~.'.  s<'='((~'~+<+B= ~B'
//    ~B=(<<<+<<+~.    .h- ~BD'++    .~<<B< +B'
//    ~B=(<<~~~('.     .DzzN++Dhs      '-D~ =B.
//    <B+<<-  .   .     ~ss(  <s'  .    ~B. zD.
//    <h--'         .  .          .     '(  hh
//    =z                         .         .Ds
//    zs                                   'B=
//    h=               -=-                 ~B~
//    z=              'DN=                 +N-
//    h=              =z(s                 zh.
//    .B+          .-~=D~<z                 D=
//    .hz      -=szDDzs< s+                'D<
//    Dz      sNhs(-   .B~                ~B'
//    hz      .'.     ~hD.                'B<
//    =D.         '~+DBh-                  <h.
//    (B'      ~+hBDDs-                    .B~
//    -B(      =h+~-                        <-
//    .B+
//     s<
//
//  SpeechRecoginzerCore.h
//  SpeakRecognizerTakePhoto
//
//  Created by Sylar on 16/12/9.
//  Copyright © 2016年 Sylar. All rights reserved.
//


/*
 
 @warning:  仅用于 iOS 10.0 系统以上 !!!!!!!!!!!
 
 
 苹果官方自带框架语音识别模块
 
 即时识别
 
 @warning: 识别时长最长为1min, 相应设置好逻辑
 
 @Usage:
 
        1.传入地区编码 -> 如中国大陆 :zh-CN  美帝:en-US 等初始化一个Speech
        2.startRecording ->  遵守代理方法 -> 可获得回调自动识别的文字
        3.用完时候记得 stopRecording
 */

#import <Foundation/Foundation.h>

@protocol SpeechRecognizerCoreDelegate <NSObject>

@optional

-(void)speechRecognizerDidRecognizeText:(NSString*)text;

-(void)speechRecognizerDidFinishRecognize;

-(void)speechRecogizerWithFatalerror:(NSError*)error;

@end

@interface SpeechRecoginzerCore : NSObject

//获得权限，是否能使用框架
@property(nonatomic,readonly,assign) BOOL isUseable;

@property(nonatomic,assign)id<SpeechRecognizerCoreDelegate> delegate;


//获得当前是否正在识别状态
@property(nonatomic,assign,readonly)BOOL isRecording;


//传入地区编码初始化
-(instancetype)initWithLocaleIdentifier:(NSString*)localeIdentifier;


//开始识别
-(void)startRecording;


//停止识别
-(void)stopRecording;


//语音识别Data
@property (nonatomic, assign) Float32 *FrequencyData;


//生成点数据
@property (nonatomic, strong) NSMutableArray <NSNumber *>*FrequencyValue;

@end
