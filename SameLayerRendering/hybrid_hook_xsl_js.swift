//
//  hybrid_hook_xsl_js.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/28.
//

import Foundation

func hybridHookXSLJS() -> String {
    return """
;(function(){
    "use strict";
    class $ElementName extends HTMLElement {
        //向Nativer发送消息
        messageToNative(params) {
            params['xsl_id'] = this.lowerClassName();
            if (window.XWebView && window.XWebView.callNative) {
                window.XWebView && window.XWebView.callNative('XWidgetPlugin', params['methodType'], params, params['callbackName'], params['callbackId']);
            }
        }
        $customfunction lowerClassName() {
            if (!this.x_className) {
                this.x_className = '$Element-Name' + this.constructor.index++;
            }
            return this.x_className;
        }
        //需要观察的属性
        static get observedAttributes() {
            return ['$obsevers'];
        }
        constructor() {
            super();
            if (!$ElementName.index) {
                $ElementName.index = 0;
                $ElementName.isAddStyle = false;
            }
            this.canUse = window.XWidget && window.XWidget.canIUse('$Element-Name');
            this.x_className = '';
            this.element_name = '$Element-Name';
            //💣💣💣巨坑, eg: 在Vue中如果有video标签，要加setTimeout，否则Native端拿到到name属性💣💣💣
            setTimeout(() => {
               this.appendChild()
            }, 0)
            //通知Nativer创建
            this.messageToNative({
                'methodType': 'createXsl'
            });
        }
        //同层渲染的关键
        appendChild() {
            if (!$ElementName.isAddStyle) {
                var style = document.createElement('style');
                var xsl_style = `{ display:block; overflow:scroll; -webkit-overflow-scrolling: touch;}`;
                style.textContent = '$Element-Name' + `::-webkit-scrollbar { display: none; width: 0; height: 0; color: transparent; }` + '$Element-Name' + xsl_style;
                document.body.appendChild(style);
                $ElementName.isAddStyle = true;
            }
            const shadowroot = this.attachShadow({
                mode: 'open'
            });
            var a = document.createElement('div');
            a.style.height = '200%';
            shadowroot.appendChild(a);
        }
        //通知Nativer添加
        connectedCallback() {
            this.className = this.lowerClassName();
            let attributes = {};
            Object.assign(attributes, ...[...this.attributes].map(attr => ({ [attr.name]: attr.value })));
            this.messageToNative({
                'methodType': 'addXsl',
                ...attributes
            })
        }
        //通知Nativer移除
        disconnectedCallback() {
            this.messageToNative({
                'methodType': 'removeXsl'
            })
        }
        //attribute变化通知Native
        attributeChangedCallback(name, oldValue, newValue) {
            if (oldValue == newValue) {
                return;
            }
            if (name == 'hidden') {
                if (newValue != null) {
                    this.style.display = 'none';
                } else {
                    this.style.removeProperty('display');
                }
                return;
            } else if (name == 'class') {
                return;
            }
            var params = {
                'methodType': 'changeXsl',
                'methodName': name,
                'oldValue': oldValue,
                'newValue': newValue
            };
            this.messageToNative(params);
        }
    }
    customElements.define('$Element-Name', $ElementName)
})();
"""
}
