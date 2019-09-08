//
//  ZWHtmlDefine.h
//  ZWebServer
//
//  Created by Wei on 2018/10/18.
//  Copyright © 2018年 Wei. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define ZWToString(str) #str

static const NSString *htmlHeader = @ZWToString(<!doctype html><html lang='cn'><head><meta charset='utf-8'><title>%@</title></head><body>%@</body></html>);

static const NSString *itemTag = @ZWToString(<li><a href='%@%@'>%@</a></li>);
static const NSString *line = @ZWToString(--------------------------------------------);

static const NSString *consoleScriptHtml =
@ZWToString(<script language='javascript' type='text/javascript'>
            var wsUri ='ws://' + window.location.host + '/console';
            var staticWebsocket;
            var output;
            
            function init() {
                output = document.getElementById('output');
                if ('WebSocket' in window) {
                    tryWebSocket();
                } else {
                    addLog('<span style=\'color: red;\'>NO WEBSOCKET</span>');
                }
            }

            function tryWebSocket() {
                staticWebsocket = new WebSocket(wsUri);
                staticWebsocket.onopen = function(evt) {
                    addLog('<span style=\'color: green;\'>'+ 'Has Connected to iOS Logger, Host:' + window.location.host + '</span>');
                };
                staticWebsocket.onclose = function(evt) {
                    addLog('<span style=\'color: green;\'>'+ 'Disconnected' +'</span>');
                };
                staticWebsocket.onmessage = function(evt) {
                    addLog('<span style=\'color: black;\'>'+ evt.data +'</span>');
                    scrollToBottom();
                };
                staticWebsocket.onerror = function(evt) {
                    addLog('<span style=\'color: red;\'>'+ evt.data +'</span>');
                };
            }

            
            function doSend(message) {
                addLog('<span style=\'color: blue;\'>' + 'Send: ' + message + '</span>');
                staticWebsocket.send(message);
            }
            
            function scrollToBottom(){
                window.scrollTo(0, document.documentElement.scrollHeight || document.body.scrollHeight);
            }
            function addLog(message) {
                var pre = document.createElement('p');
                pre.style.wordWrap = 'break-word';
                pre.innerHTML = message;
                output.appendChild(pre);
            }
            window.addEventListener('load', init, false);
</script>
<h2>iOS Remote Logger</h2>
<div id='output'></div>);


static const NSString *uiScriptHtml =
@ZWToString(<script language='javascript' type='text/javascript'>
            var output;
            var source = %@;
            function init() {
                output = document.getElementById('output');
                runloopGenerate(source, output);
            }
            function runloopGenerate(array, current) {
                var tmp;
                for (var i = 0; i < array.length; ++i) {
                    var obj = array[i];
                    if (obj instanceof Array) {
                        runloopGenerate(obj, tmp);
                    } else {
                        tmp = generateSquare(obj);
                        current.appendChild(tmp);
                    }
                }
            }
            
            function generateSquare(obj){
                var square = generateElement('div', obj.top, obj.left, obj.width, obj.height);
                square.style.backgroundColor = generateColor();
//                square.onmouseover = function message(evt) {
//                    console.log(obj);
//                };
                if (obj.text != 'null') {
                    var span = generateElement('span', (obj.height - obj.fontSize)/2, 0, obj.width, obj.fontSize);
                    span.innerText = obj.text;
                    span.style.fontSize = obj.fontSize + 'px';
                    span.style.textAlign = 'center';
                    span.style.lineHeight =  obj.fontSize + 'px';

                    if (obj. textAlign == 0 || obj. textAlign == 4 || obj. textAlign == 3) {
                        span.style.textAlign = 'left';
                    } else if (obj. textAlign == 2){
                        span.style.textAlign = 'right';
                    }
                    
                    square.style.verticalAlign = 'middle';
                    square.appendChild(span);
                } else if (obj.image != 'null') {
                    var img = generateElement('img', 0, 0, obj.width, obj.height);
                    img.setAttribute('src','data:image/png;base64,' + obj.image);
                    square.appendChild(img);
                    square.style.backgroundColor = null;
                }
//                square.style.borderColor = generateColor();
//                square.style.borderStyle = 'solid';
//                square.style.borderWidth = '0.5px';
                
                return square;
            }
            
            function generateElement(type, top, left, width, height) {
                var v = document.createElement(type);
                v.style.position = 'absolute';
                v.style.top = top + 'px';
                v.style.left = left + 'px';
                v.style.width = width + 'px';
                v.style.height = height + 'px';
                return v;
            }
            
            function generateColor(){
                var color = ['#'];
                for (var i = 0; i < 3; ++i) {
                    var randColor = Math.round(255 * Math.random());
                    var aColor = (randColor < 16 ? '0' : '') + randColor.toString(16);
                    color.push(aColor);
                }
                color.push('af');
                
                return color.join('');
            }
            
            window.addEventListener('load', init, false);
            
            </script>
            <div id='output' style='position:absolute;left:60px;top:60px;width:375px;height:667px;background-color:gray;'></div>
            );
