//
//  Created by Jovanni Lo (@lodev09)
//  Copyright (c) 2024-present. All rights reserved.
//
//  This source code is licensed under the MIT license found in the
//  LICENSE file in the root directory of this source tree.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import "TrueSheetNavBarItemView.h"

#import <react/renderer/components/TrueSheetSpec/ComponentDescriptors.h>
#import <react/renderer/components/TrueSheetSpec/EventEmitters.h>
#import <react/renderer/components/TrueSheetSpec/Props.h>
#import <react/renderer/components/TrueSheetSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

@implementation TrueSheetNavBarItemView {
  UIView *_wrapperView;
  UIView<RCTComponentViewProtocol> *_childView;
}

@synthesize delegate = _delegate;

- (void)setDelegate:(id<TrueSheetNavBarItemViewDelegate>)delegate {
  _delegate = delegate;

  // Fabric mounts bottom-up: the child mounts into NavBarItem before
  // the Container sets itself as delegate. Re-fire the notification
  // if the wrapper was already created.
  if (_wrapperView && delegate) {
    if ([delegate respondsToSelector:@selector(navBarItemViewDidMount:type:)]) {
      [delegate navBarItemViewDidMount:_wrapperView type:_itemType];
    }
  }
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<TrueSheetNavBarItemComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const TrueSheetNavBarItemProps>();
    _props = defaultProps;

    _itemType = TSNavBarItemTypeTitle;
    self.hidden = YES;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &newProps = *std::static_pointer_cast<TrueSheetNavBarItemProps const>(props);

  auto typeStr = toString(newProps.type);
  if (typeStr == "left") {
    _itemType = TSNavBarItemTypeLeft;
  } else if (typeStr == "right") {
    _itemType = TSNavBarItemTypeRight;
  } else {
    _itemType = TSNavBarItemTypeTitle;
  }

  [super updateProps:props oldProps:oldProps];
}

- (void)updateLayoutMetrics:(const facebook::react::LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const facebook::react::LayoutMetrics &)oldLayoutMetrics {
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];

  // The NavBarItem's size (from Yoga) reflects its child content size
  // because it uses position:absolute with no explicit dimensions.
  // Use this to size the wrapper that lives in the navigation bar.
  if (_wrapperView) {
    CGFloat width = layoutMetrics.frame.size.width;
    CGFloat height = layoutMetrics.frame.size.height;
    if (width > 0 && height > 0) {
      _wrapperView.frame = CGRectMake(0, 0, width, height);
      if (_childView) {
        _childView.frame = CGRectMake(0, 0, width, height);
      }
    }
  }
}

- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
  // Do NOT call super — we reparent the child into a wrapper view
  _wrapperView = [[UIView alloc] init];
  _childView = childComponentView;

  [_wrapperView addSubview:childComponentView];

  if ([self.delegate respondsToSelector:@selector(navBarItemViewDidMount:type:)]) {
    [self.delegate navBarItemViewDidMount:_wrapperView type:_itemType];
  }
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
  [childComponentView removeFromSuperview];
  _wrapperView = nil;
  _childView = nil;

  if ([self.delegate respondsToSelector:@selector(navBarItemViewDidUnmount:)]) {
    [self.delegate navBarItemViewDidUnmount:_itemType];
  }
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  _wrapperView = nil;
  _childView = nil;
  _itemType = TSNavBarItemTypeTitle;
}

@end

Class<RCTComponentViewProtocol> TrueSheetNavBarItemCls(void) {
  return TrueSheetNavBarItemView.class;
}

#endif
