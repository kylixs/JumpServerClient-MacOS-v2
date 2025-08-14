#!/usr/bin/env python3

import subprocess
import json
import plistlib
import sys

def run_command(cmd):
    """运行命令并返回输出"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return 1, "", str(e)

def get_lshandlers():
    """获取当前的LSHandlers配置"""
    cmd = "defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers"
    returncode, stdout, stderr = run_command(cmd)
    
    if returncode != 0:
        print(f"❌ 获取LSHandlers失败: {stderr}")
        return None
    
    try:
        # 将plist格式转换为Python对象
        # 首先转换为XML格式
        cmd_xml = "defaults export com.apple.LaunchServices/com.apple.launchservices.secure /tmp/lshandlers.plist"
        run_command(cmd_xml)
        
        # 读取plist文件
        with open('/tmp/lshandlers.plist', 'rb') as f:
            plist_data = plistlib.load(f)
        
        return plist_data.get('LSHandlers', [])
    except Exception as e:
        print(f"❌ 解析LSHandlers失败: {e}")
        return None

def clean_jms_handlers(handlers):
    """清理重复的jms协议处理器"""
    print("🔍 开始清理重复的jms协议处理器...")
    
    cleaned_handlers = []
    jms_handlers_found = []
    
    for handler in handlers:
        url_scheme = handler.get('LSHandlerURLScheme')
        role_all = handler.get('LSHandlerRoleAll')
        
        if url_scheme == 'jms':
            jms_handlers_found.append({
                'LSHandlerRoleAll': role_all,
                'LSHandlerURLScheme': url_scheme
            })
            print(f"🔍 找到jms处理器: {role_all}")
        else:
            # 保留非jms的处理器
            cleaned_handlers.append(handler)
    
    print(f"\n📊 统计结果:")
    print(f"   总处理器数量: {len(handlers)}")
    print(f"   jms处理器数量: {len(jms_handlers_found)}")
    print(f"   清理后数量: {len(cleaned_handlers)}")
    
    # 显示找到的jms处理器
    print(f"\n📋 找到的jms处理器:")
    for i, handler in enumerate(jms_handlers_found, 1):
        print(f"   {i}. {handler['LSHandlerRoleAll']}")
    
    return cleaned_handlers, jms_handlers_found

def set_lshandlers(handlers):
    """设置新的LSHandlers配置"""
    try:
        # 创建新的plist数据
        plist_data = {'LSHandlers': handlers}
        
        # 写入临时文件
        with open('/tmp/lshandlers_new.plist', 'wb') as f:
            plistlib.dump(plist_data, f)
        
        # 导入新的配置
        cmd = "defaults import com.apple.LaunchServices/com.apple.launchservices.secure /tmp/lshandlers_new.plist"
        returncode, stdout, stderr = run_command(cmd)
        
        if returncode != 0:
            print(f"❌ 设置LSHandlers失败: {stderr}")
            return False
        
        return True
    except Exception as e:
        print(f"❌ 设置LSHandlers异常: {e}")
        return False

def reset_launch_services():
    """重置Launch Services数据库"""
    print("🔄 重置Launch Services数据库...")
    
    commands = [
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user",
        "killall Finder"
    ]
    
    for cmd in commands:
        print(f"   执行: {cmd}")
        returncode, stdout, stderr = run_command(cmd)
        if returncode != 0:
            print(f"   ⚠️ 命令执行警告: {stderr}")
        else:
            print(f"   ✅ 命令执行成功")

def main():
    print("🧹 JMS协议处理器清理工具")
    print("=" * 40)
    print()
    
    # 1. 获取当前配置
    print("📋 获取当前LSHandlers配置...")
    handlers = get_lshandlers()
    if handlers is None:
        sys.exit(1)
    
    # 2. 清理重复条目
    cleaned_handlers, jms_handlers = clean_jms_handlers(handlers)
    
    if not jms_handlers:
        print("✅ 未找到jms协议处理器，无需清理")
        return
    
    # 3. 确认清理
    print(f"\n❓ 确认要删除所有 {len(jms_handlers)} 个jms协议处理器吗？")
    print("   这将清除所有jms://协议的关联")
    
    response = input("   输入 'yes' 确认清理: ").strip().lower()
    if response != 'yes':
        print("❌ 用户取消操作")
        return
    
    # 4. 应用清理
    print("\n🔧 应用清理配置...")
    if set_lshandlers(cleaned_handlers):
        print("✅ LSHandlers配置更新成功")
    else:
        print("❌ LSHandlers配置更新失败")
        return
    
    # 5. 重置Launch Services
    reset_launch_services()
    
    # 6. 验证结果
    print("\n🔍 验证清理结果...")
    new_handlers = get_lshandlers()
    if new_handlers is not None:
        jms_count = sum(1 for h in new_handlers if h.get('LSHandlerURLScheme') == 'jms')
        print(f"   当前jms处理器数量: {jms_count}")
        
        if jms_count == 0:
            print("✅ 所有jms协议处理器已成功清理")
        else:
            print(f"⚠️ 仍有 {jms_count} 个jms处理器未清理")
    
    print("\n🎉 清理完成！")
    print("💡 提示: 如需重新注册jms协议，请运行注册脚本")

if __name__ == "__main__":
    main()
