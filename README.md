# Rhythm

> 帮助你找到使用电脑的节奏

Rhythm 是一款运行在 macOS 上的休息提醒工具，帮助你在长时间使用电脑时保持健康的工作节奏。

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

## 功能

- **休息提醒**：自定义工作时长和休息时长，时间到后弹出全屏半透明遮罩提醒休息
- **随机微休息**：在设定的时间区间内随机触发一次 10 秒微休息提示音，保护眼睛
- **ESC 跳过**：全屏遮罩时按 ESC 可跳过当前休息
- **锁屏重置**：电脑锁屏或开启屏保后自动重置计时
- **数据记录**：记录每次休息时长、是否跳过，按日期分组展示
- **提示音定制**：支持选择系统声音或上传自定义音效
- **菜单栏常驻**：在菜单栏实时显示距下次休息的倒计时

## 截图

菜单栏显示倒计时，点击展开控制菜单。休息时弹出全屏半透明遮罩，显示剩余时间。

## 安装

### 从源码构建

1. 确保已安装 Xcode 15+
2. 克隆仓库：
   ```bash
   git clone https://github.com/huanhaihu/Rhythm.git
   cd Rhythm
   ```
3. 生成图标：
   ```bash
   swift scripts/generate_icon.swift
   ```
4. 用 Xcode 打开 `Rhythm.xcodeproj`，选择目标设备为 My Mac，点击运行

## 使用

1. 启动后 Rhythm 自动出现在菜单栏（波形图标 + 倒计时）
2. 点击菜单栏图标可查看状态、立即休息或打开设置
3. 工作时长结束后，全屏遮罩自动出现，倒计时结束后自动关闭
4. 微休息在工作期间随机触发，播放提示音并显示 10 秒轻遮罩
5. 所有休息记录可在「设置 → 统计」中查看

## 项目结构

```
Rhythm/
├── Core/
│   ├── TimerEngine.swift        # 核心计时状态机
│   ├── Settings.swift           # 用户设置（AppStorage）
│   ├── SoundPlayer.swift        # 提示音播放
│   └── ScreenLockMonitor.swift  # 锁屏检测
├── UI/
│   ├── OverlayWindow.swift      # 全屏遮罩 NSWindow
│   ├── OverlayView.swift        # 遮罩 SwiftUI 视图
│   ├── OverlayWindowManager.swift
│   ├── MenuBarView.swift        # 菜单栏内容
│   ├── SettingsView.swift       # 设置页
│   ├── StatsView.swift          # 统计页
│   └── MainView.swift           # 主窗口
├── Data/
│   ├── Session.swift            # 休息记录模型
│   └── SessionStore.swift       # JSON 持久化
└── RhythmApp.swift              # 入口
```

## 开发计划

- [ ] 开机自启动
- [ ] 多显示器支持
- [ ] 自定义休息提示语
- [ ] 数据导出（CSV）
- [ ] 周/月统计图表

## License

MIT © [huanhaihu](https://github.com/huanhaihu)
