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
        messageToNative(params) {
            params['xsl_id'] = this.lowerClassName();
            params['hybrid_xsl_id'] = this.hybrid_xsl_id;
            console.log(params)
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
        
        finalClassName() {
            if (!this.final_className) {
                this.final_className = this.lowerClassName() + ' ' + this.className;
            }
            return this.final_className;
        }
        
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
            this.final_className = '';
            this.element_name = '$Element-Name';
            this.display_style = '';
            this.hybrid_xsl_id = '';
            if (!$ElementName.isAddStyle) {
                var style = document.createElement('style');
                var xsl_style = `{ display:block; overflow:scroll; }`;
                style.textContent = '$Element-Name' + `::-webkit-scrollbar { display: none; width: 0; height: 0; color: transparent; }` + '$Element-Name' + xsl_style;
                document.body.appendChild(style);
                $ElementName.isAddStyle = true;
            }
            const shadowroot = this.attachShadow({
                mode: 'open'
            });
            var a = document.createElement('div');
            a.style.height = '102%';
            shadowroot.appendChild(a);
            this.messageToNative({
                'methodType': 'createXsl'
            });
        }
        connectedCallback() {
            this.className = this.finalClassName();
            let attributes = {};
            Object.assign(attributes, ...[...this.attributes].map(attr => ({ [attr.name]: attr.value })));
            this.messageToNative({
                'methodType': 'addXsl',
                ...attributes
            })
        }
        
        disconnectedCallback() {
            this.messageToNative({
                'methodType': 'removeXsl'
            })
        }
        attributeChangedCallback(name, oldValue, newValue) {
            if (oldValue == newValue) {
                return;
            }
            if (name == 'hidden') {
                if (newValue != null) {
                    this.display_style = this.style.display;
                    this.style.display = 'none';
                } else {
                    this.style.display = this.display_style;
                }
                return;
            } else if (name == 'class') {
                return;
            } else if (name == 'hybrid_xsl_id') {
                this.hybrid_xsl_id = newValue;
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
