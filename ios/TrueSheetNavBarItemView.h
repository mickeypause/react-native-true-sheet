//
//  Created by Jovanni Lo (@lodev09)
//  Copyright (c) 2024-present. All rights reserved.
//
//  This source code is licensed under the MIT license found in the
//  LICENSE file in the root directory of this source tree.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TSNavBarItemType) {
  TSNavBarItemTypeTitle = 0,
  TSNavBarItemTypeLeft,
  TSNavBarItemTypeRight,
};

@protocol TrueSheetNavBarItemViewDelegate <NSObject>
@optional
- (void)navBarItemViewDidMount:(UIView *)wrapperView type:(TSNavBarItemType)type;
- (void)navBarItemViewDidUnmount:(TSNavBarItemType)type;
@end

@interface TrueSheetNavBarItemView : RCTViewComponentView

@property (nonatomic, assign, readonly) TSNavBarItemType itemType;
@property (nonatomic, weak, nullable) id<TrueSheetNavBarItemViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

#endif
