//
//  ContainerHookView.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import Foundation
import UIKit

public class ContainerHookView: UIView {
    
    var nativeElementInteractionEnabled = false
    
    var viewDidRemoveWindow: () -> Void = { }
    
    public override func conforms(to aProtocol: Protocol) -> Bool {
        if NSStringFromProtocol(aProtocol) == "WKNativelyInteractible" {
            return nativeElementInteractionEnabled
        }
        return super.conforms(to: aProtocol)
    }
    

  
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if (self.window == nil) {
            viewDidRemoveWindow()
        }
    }

    // 源码
    /*@implementation UIView (WKHitTesting)

    - (UIView *)_web_findDescendantViewAtPoint:(CGPoint)point withEvent:(UIEvent *)event
    {
        Vector<UIView *, 16> viewsAtPoint;
        WebKit::collectDescendantViewsAtPoint(viewsAtPoint, self, point, event);

        LOG_WITH_STREAM(UIHitTesting, stream << (void*)self << "_web_findDescendantViewAtPoint " << WebCore::FloatPoint(point) << " found " << viewsAtPoint.size() << " views");

        for (auto *view : WTF::makeReversedRange(viewsAtPoint)) {
            if ([view conformsToProtocol:@protocol(WKNativelyInteractible)]) {
                LOG_WITH_STREAM(UIHitTesting, stream << " " << (void*)view << " is natively interactible");
                CGPoint subviewPoint = [view convertPoint:point fromView:self];
                return [view hitTest:subviewPoint withEvent:event];
            }

            if ([view isKindOfClass:[WKChildScrollView class]]) {
                if (WebKit::isScrolledBy((WKChildScrollView *)view, viewsAtPoint.last())) {
                    LOG_WITH_STREAM(UIHitTesting, stream << " " << (void*)view << " is child scroll view and scrolled by " << (void*)viewsAtPoint.last());
                    return view;
                }
            }

            if ([view isKindOfClass:WebKit::scrollViewScrollIndicatorClass()] && [view.superview isKindOfClass:WKChildScrollView.class]) {
                if (WebKit::isScrolledBy((WKChildScrollView *)view.superview, viewsAtPoint.last())) {
                    LOG_WITH_STREAM(UIHitTesting, stream << " " << (void*)view << " is the scroll indicator of child scroll view, which is scrolled by " << (void*)viewsAtPoint.last());
                    return view;
                }
            }

            LOG_WITH_STREAM(UIHitTesting, stream << " ignoring " << [view class] << " " << (void*)view);
        }

        LOG_WITH_STREAM(UIHitTesting, stream << (void*)self << "_web_findDescendantViewAtPoint found no interactive views");
        return nil;
    }

    @end*/

}
