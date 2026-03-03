//
//  Created by Jovanni Lo (@lodev09)
//  Copyright (c) 2024-present. All rights reserved.
//
//  This source code is licensed under the MIT license found in the
//  LICENSE file in the root directory of this source tree.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import "TrueSheetContainerView.h"
#import "TrueSheetContentView.h"
#import "TrueSheetFooterView.h"
#import "TrueSheetHeaderView.h"
#import "TrueSheetViewController.h"
#import "core/TrueSheetKeyboardObserver.h"
#import "utils/WindowUtil.h"
#import "TrueSheetNavBarItemView.h"

#import <react/renderer/components/TrueSheetSpec/ComponentDescriptors.h>
#import <react/renderer/components/TrueSheetSpec/EventEmitters.h>
#import <react/renderer/components/TrueSheetSpec/Props.h>
#import <react/renderer/components/TrueSheetSpec/RCTComponentViewHelpers.h>

#import <React/RCTConversions.h>
#import <React/RCTLog.h>
#import <react/renderer/core/LayoutMetrics.h>

using namespace facebook::react;

@implementation ScrollableOptions

- (instancetype)init {
  if (self = [super init]) {
    _keyboardScrollOffset = 0;
    _scrollingExpandsSheet = YES;
  }
  return self;
}

@end

@interface TrueSheetContainerView () <TrueSheetContentViewDelegate, TrueSheetHeaderViewDelegate>
@interface TrueSheetContainerView () <TrueSheetContentViewDelegate, TrueSheetHeaderViewDelegate,
                                      TrueSheetNavBarItemViewDelegate>
@end

@implementation TrueSheetContainerView {
  TrueSheetContentView *_contentView;
  TrueSheetHeaderView *_headerView;
  TrueSheetFooterView *_footerView;
  TrueSheetKeyboardObserver *_keyboardObserver;
  BOOL _scrollableSet;

  TrueSheetNavBarItemView *_navBarTitleView;
  TrueSheetNavBarItemView *_navBarLeftView;
  TrueSheetNavBarItemView *_navBarRightView;

  // Stored wrappers for deferred delegate notification.
  // Fabric mounts bottom-up so nav bar item wrappers arrive before
  // TrueSheetView sets itself as our delegate.
  UIView *_pendingNavBarTitleWrapper;
  UIView *_pendingNavBarLeftWrapper;
  UIView *_pendingNavBarRightWrapper;
}

@synthesize delegate = _delegate;

- (void)setDelegate:(id<TrueSheetContainerViewDelegate>)delegate {
  _delegate = delegate;

  // Flush any nav bar item wrappers that arrived before the delegate was set.
  if (delegate) {
    [self flushPendingNavBarWrapper:_pendingNavBarTitleWrapper type:TSNavBarItemTypeTitle];
    [self flushPendingNavBarWrapper:_pendingNavBarLeftWrapper type:TSNavBarItemTypeLeft];
    [self flushPendingNavBarWrapper:_pendingNavBarRightWrapper type:TSNavBarItemTypeRight];
  }
}

- (void)flushPendingNavBarWrapper:(UIView *)wrapper type:(TSNavBarItemType)type {
  if (!wrapper) return;
  if ([_delegate respondsToSelector:@selector(containerViewNavBarItemDidMount:type:)]) {
    [_delegate containerViewNavBarItemDidMount:wrapper type:(NSInteger)type];
  }
}

#pragma mark - Initialization

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<TrueSheetContainerViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const TrueSheetContainerViewProps>();
    _props = defaultProps;

    self.backgroundColor = [UIColor clearColor];
    _contentView = nil;
    _headerView = nil;
    _footerView = nil;
    _scrollableSet = NO;
  }
  return self;
}

#pragma mark - Layout

- (void)layoutSubviews {
  [super layoutSubviews];
  [_contentView updateScrollViewHeight];
}

- (CGFloat)contentHeight {
  return _contentView ? _contentView.frame.size.height : 0;
}

- (CGFloat)headerHeight {
  return _headerView ? _headerView.frame.size.height : 0;
}

- (void)layoutFooter {
  if (_footerView) {
    CGFloat height = _footerView.frame.size.height;
    if (height > 0) {
      [_footerView setupConstraintsWithHeight:height];
    }
  }
}

- (void)setScrollableEnabled:(BOOL)scrollableEnabled {
  _scrollableEnabled = scrollableEnabled;
  _scrollableSet = YES;
}

- (void)setScrollableOptions:(ScrollableOptions *)scrollableOptions {
  _scrollableOptions = scrollableOptions;
  _contentView.keyboardScrollOffset = scrollableOptions ? scrollableOptions.keyboardScrollOffset : 0;
}

- (void)setupScrollable {
  if (_scrollableSet && _contentView) {
    CGFloat bottomInset = 0;
    if (_insetAdjustment == (NSInteger)TrueSheetViewInsetAdjustment::Automatic) {
      bottomInset = [WindowUtil keyWindow].safeAreaInsets.bottom;
    }
    [_contentView setupScrollable:_scrollableEnabled bottomInset:bottomInset];
  }
}

#pragma mark - Child Component Mounting

- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
  [super mountChildComponentView:childComponentView index:index];

  if ([childComponentView isKindOfClass:[TrueSheetContentView class]]) {
    if (_contentView != nil) {
      RCTLogWarn(@"TrueSheet: Container can only have one content component.");
      return;
    }
    _contentView = (TrueSheetContentView *)childComponentView;
    _contentView.delegate = self;
  }

  if ([childComponentView isKindOfClass:[TrueSheetHeaderView class]]) {
    if (_headerView != nil) {
      RCTLogWarn(@"TrueSheet: Container can only have one header component.");
      return;
    }
    _headerView = (TrueSheetHeaderView *)childComponentView;
    _headerView.delegate = self;
    [self headerViewDidChangeSize:_headerView.frame.size];
  }

  if ([childComponentView isKindOfClass:[TrueSheetFooterView class]]) {
    if (_footerView != nil) {
      RCTLogWarn(@"TrueSheet: Container can only have one footer component.");
      return;
    }
    _footerView = (TrueSheetFooterView *)childComponentView;
  }

  if ([childComponentView isKindOfClass:[TrueSheetNavBarItemView class]]) {
    TrueSheetNavBarItemView *navBarItem = (TrueSheetNavBarItemView *)childComponentView;
    navBarItem.delegate = self;
    switch (navBarItem.itemType) {
      case TSNavBarItemTypeTitle:
        _navBarTitleView = navBarItem;
        break;
      case TSNavBarItemTypeLeft:
        _navBarLeftView = navBarItem;
        break;
      case TSNavBarItemTypeRight:
        _navBarRightView = navBarItem;
        break;
    }
  }
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
  if ([childComponentView isKindOfClass:[TrueSheetContentView class]]) {
    _contentView.delegate = nil;
    _contentView = nil;
  }

  if ([childComponentView isKindOfClass:[TrueSheetHeaderView class]]) {
    _headerView.delegate = nil;
    _headerView = nil;
    [self headerViewDidChangeSize:CGSizeZero];
  }

  if ([childComponentView isKindOfClass:[TrueSheetFooterView class]]) {
    _footerView = nil;
  }

  if ([childComponentView isKindOfClass:[TrueSheetNavBarItemView class]]) {
    TrueSheetNavBarItemView *navBarItem = (TrueSheetNavBarItemView *)childComponentView;
    NSInteger type = navBarItem.itemType;
    navBarItem.delegate = nil;
    switch (type) {
      case TSNavBarItemTypeTitle:
        _navBarTitleView = nil;
        break;
      case TSNavBarItemTypeLeft:
        _navBarLeftView = nil;
        break;
      case TSNavBarItemTypeRight:
        _navBarRightView = nil;
        break;
    }
    if ([self.delegate respondsToSelector:@selector(containerViewNavBarItemDidUnmount:)]) {
      [self.delegate containerViewNavBarItemDidUnmount:type];
    }
  }

  [super unmountChildComponentView:childComponentView index:index];
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  [super updateProps:props oldProps:oldProps];
}

#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics {
  // Intentionally skip super - AutoLayout handles container's frame, not Yoga
}

#pragma mark - TrueSheetContentViewDelegate

- (void)contentViewDidChangeSize:(CGSize)newSize {
  [self.delegate containerViewContentDidChangeSize:newSize];
}

- (void)contentViewScrollViewDidChange {
  [self.delegate containerViewScrollViewDidChange];
}

#pragma mark - TrueSheetHeaderViewDelegate

- (void)headerViewDidChangeSize:(CGSize)newSize {
  [self.delegate containerViewHeaderDidChangeSize:newSize];
}

#pragma mark - Keyboard Observer

- (void)setupKeyboardObserverWithViewController:(UIViewController *)viewController {
  [self cleanupKeyboardObserver];

  _keyboardObserver = [[TrueSheetKeyboardObserver alloc] init];
  _keyboardObserver.viewController = (TrueSheetViewController *)viewController;

  if (_contentView) {
    _contentView.keyboardObserver = _keyboardObserver;
    [_keyboardObserver addDelegate:_contentView];
  }

  if (_footerView) {
    _footerView.keyboardObserver = _keyboardObserver;
    [_keyboardObserver addDelegate:_footerView];
  }

  [_keyboardObserver start];
}

- (void)cleanupKeyboardObserver {
  if (_keyboardObserver) {
    [_keyboardObserver stop];
    _keyboardObserver = nil;
  }

  _contentView.keyboardObserver = nil;
  _footerView.keyboardObserver = nil;
}

#pragma mark - TrueSheetNavBarItemViewDelegate

- (void)navBarItemViewDidMount:(UIView *)wrapperView type:(TSNavBarItemType)type {
  // Store wrapper for deferred notification if delegate isn't set yet.
  switch (type) {
    case TSNavBarItemTypeTitle:
      _pendingNavBarTitleWrapper = wrapperView;
      break;
    case TSNavBarItemTypeLeft:
      _pendingNavBarLeftWrapper = wrapperView;
      break;
    case TSNavBarItemTypeRight:
      _pendingNavBarRightWrapper = wrapperView;
      break;
  }

  if ([self.delegate respondsToSelector:@selector(containerViewNavBarItemDidMount:type:)]) {
    [self.delegate containerViewNavBarItemDidMount:wrapperView type:(NSInteger)type];
  }
}

- (void)navBarItemViewDidUnmount:(TSNavBarItemType)type {
  switch (type) {
    case TSNavBarItemTypeTitle:
      _pendingNavBarTitleWrapper = nil;
      break;
    case TSNavBarItemTypeLeft:
      _pendingNavBarLeftWrapper = nil;
      break;
    case TSNavBarItemTypeRight:
      _pendingNavBarRightWrapper = nil;
      break;
  }

  if ([self.delegate respondsToSelector:@selector(containerViewNavBarItemDidUnmount:)]) {
    [self.delegate containerViewNavBarItemDidUnmount:(NSInteger)type];
  }
}

@end

Class<RCTComponentViewProtocol> TrueSheetContainerViewCls(void) {
  return TrueSheetContainerView.class;
}

#endif
