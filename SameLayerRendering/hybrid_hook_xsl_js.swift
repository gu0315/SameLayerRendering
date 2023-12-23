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
        //向Native发送消息
        messageToNative(params) {
            params['xsl_id'] = this.lowerClassName();
            if (window.XWebView && window.XWebView.callNative) {
                window.XWebView && window.XWebView.callNative('XWidgetPlugin', params['methodType'], params, params['callbackName'], params['callbackId']);
            }
        }
        //className->和Native映射
        lowerClassName() {
            if (!this.x_className) {
                this.x_className = '$Element-Name' + $ElementName.index++;
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
            this.last_display_style = '';
            //💣💣💣巨坑, eg: 在Vue中如果有video标签，要加setTimeout|queueMicrotask，否则Native端拿到到name属性
            queueMicrotask(() => {
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
            });
            //通知Native创建
            this.messageToNative({
               'methodType': 'createXsl'
            });
        }
        //attribute变化通知Native
        attributeChangedCallback(name, oldValue, newValue) {
            if (oldValue == newValue) {
                return;
            }
            if (name == 'hidden') {
                if (newValue != null) {
                    this.last_display_style = this.style.display;
                    this.style.display = 'none';
                } else {
                    this.style.display = this.last_display_style;
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
        //上树通知Native
        connectedCallback() {
            this.className = this.lowerClassName();
            let attributes = {};
            Object.assign(attributes, ...[...this.attributes].map(attr => ({ [attr.name]: attr.value })));
            this.messageToNative({
                'methodType': 'addXsl',
                ...attributes
            })
        }
        adoptedCallback() {
            // TODO:
        }
        //通知Native移除
        disconnectedCallback() {
            this.messageToNative({
                'methodType': 'removeXsl'
            })
        }
    }
    customElements.define('$Element-Name', $ElementName)
})();
"""
}
