#!/usr/bin/env python3

"""
JMS协议注册检查脚本
准确检查jms://协议的注册状态和处理程序位置
"""

import subprocess
import re
import os
import plistlib
from collections import defaultdict

def get_lsregister_dump():
    """获取Launch Services注册数据"""
    try:
        result = subprocess.run([
            '/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister',
            '-dump'
        ], capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ 获取Launch Services数据失败: {e}")
        return None

def parse_jms_handlers(dump_data):
    """解析jms协议处理程序"""
    lines = dump_data.split('\n')
    handlers = []
    
    # 查找所有jms绑定的行号
    jms_binding_lines = []
    for i, line in enumerate(lines):
        if re.search(r'bindings:.*jms:', line):
            jms_binding_lines.append(i)
    
    # 对每个jms绑定，向上查找对应的bundle信息
    seen_bundles = set()
    
    for binding_line in jms_binding_lines:
        # 向上查找bundle ID
        bundle_id = None
        for i in range(binding_line, max(0, binding_line - 50), -1):
            match = re.search(r'bundle:.*\((0x[0-9a-f]+)\)', lines[i])
            if match:
                bundle_id = match.group(1)
                break
        
        if bundle_id and bundle_id not in seen_bundles:
            seen_bundles.add(bundle_id)
            
            # 查找bundle的详细信息
            bundle_info = find_bundle_info(lines, bundle_id)
            if bundle_info:
                handlers.append(bundle_info)
    
    return handlers

def find_bundle_info(lines, bundle_id):
    """查找指定bundle ID的详细信息"""
    for i, line in enumerate(lines):
        if f'bundle id:' in line and bundle_id in line:
            # 找到bundle，解析其信息
            bundle_info = {
                'bundle_id': bundle_id,
                'path': None,
                'identifier': None,
                'name': None
            }
            
            # 向下查找path和identifier
            for j in range(i + 1, min(len(lines), i + 50)):
                if lines[j].startswith('bundle id:') or lines[j].startswith('claim id:'):
                    break
                
                if 'path:' in lines[j]:
                    path_match = re.search(r'path:\s*(.+?)\s*\(0x', lines[j])
                    if path_match:
                        bundle_info['path'] = path_match.group(1).strip()
                
                elif 'identifier:' in lines[j]:
                    id_match = re.search(r'identifier:\s*(.+)', lines[j])
                    if id_match:
                        bundle_info['identifier'] = id_match.group(1).strip()
            
            return bundle_info
    
    return None

def get_app_info(app_path):
    """获取应用程序的详细信息"""
    info = {
        'exists': os.path.exists(app_path),
        'in_trash': '.Trash' in app_path,
        'version': None,
        'build': None
    }
    
    if info['exists']:
        plist_path = os.path.join(app_path, 'Contents', 'Info.plist')
        if os.path.exists(plist_path):
            try:
                with open(plist_path, 'rb') as f:
                    plist_data = plistlib.load(f)
                    info['version'] = plist_data.get('CFBundleShortVersionString')
                    info['build'] = plist_data.get('CFBundleVersion')
            except Exception:
                pass
    
    return info

def main():
    print("🔍 JMS协议注册检查")
    print("==================")
    
    # 获取Launch Services数据
    dump_data = get_lsregister_dump()
    if not dump_data:
        return
    
    # 解析jms处理程序
    handlers = parse_jms_handlers(dump_data)
    
    print("📋 JMS协议处理程序:")
    
    if not handlers:
        print("❌ 未找到jms协议处理程序")
        print("")
        print("💡 需要注册协议:")
        print("   ./scripts/deployment/register_jms_protocol.sh")
        return
    
    active_count = 0
    
    for i, handler in enumerate(handlers, 1):
        app_path = handler['path']
        if not app_path:
            continue
            
        app_name = os.path.basename(app_path)
        print(f"\n📱 {app_name}")
        print(f"   路径: {app_path}")
        
        if handler['identifier']:
            print(f"   Bundle ID: {handler['identifier']}")
        
        # 获取应用信息
        app_info = get_app_info(app_path)
        
        if not app_info['exists']:
            print("   状态: ❌ 应用不存在")
        elif app_info['in_trash']:
            print("   状态: ⚠️ 在垃圾桶中")
        else:
            print("   状态: ✅ 活跃")
            active_count += 1
            
            if app_info['version']:
                print(f"   版本: {app_info['version']}")
            if app_info['build'] and app_info['build'] != app_info['version']:
                print(f"   构建: {app_info['build']}")
    
    # 统计和建议
    print(f"\n📊 统计:")
    print(f"   注册的处理程序: {len(handlers)} 个")
    print(f"   活跃的处理程序: {active_count} 个")
    
    print("")
    if active_count == 0:
        print("❌ 所有处理程序都不可用")
        print("💡 重新安装: cp -R build/Release/JMSProtocolHandler.app /Applications/")
        print("💡 重新注册: ./scripts/deployment/register_jms_protocol.sh")
    elif active_count == 1:
        print("✅ 协议注册正常")
    else:
        print(f"⚠️ 发现多个活跃处理程序 ({active_count} 个)")
        print("💡 清理冲突: python3 scripts/deployment/cleanup_jms_handlers.py")
    
    print("")
    print("🧪 测试协议: open 'jms://eyJ0ZXN0IjoidHJ1ZX0='")

if __name__ == '__main__':
    main()
