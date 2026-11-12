## Context
用户想知道 C 盘里哪些文件没用、可以删除。扫描已完成，完整清单已在对话中交付（C 盘 574G，已用 347G）。本计划仅执行**零风险清理项 ≈3.9 GB**；涉及用户决策（下载的安装包、eSupport 6.6G、hiberfil.sys 13.4G）和需管理员权限的项目均不动，只附操作建议。

## 清理步骤（全部为用户级目录，无需管理员）

1. **清空用户临时文件夹** `C:\Users\hellobabe\AppData\Local\Temp`（2.7 GB）
   - 删除其中内容，跳过正被运行中程序占用的文件（删除失败则跳过并继续，不报错中断）
2. **删除崩溃转储** `AppData\Local\CrashDumps` 内容（129 MB）
3. **删除缩略图缓存** `AppData\Local\Microsoft\Windows\Explorer` 下的 `thumbcache_*.db`（≈269 MB，explorer 占用的会跳过，重建自动进行）
4. **删除三个更新器缓存**（≈0.92 GB）：
   - `AppData\Local\qoder-cn-updater`（259M）
   - `AppData\Local\@genieworkbuddy-desktop-updater`（430M）
   - `AppData\Local\@opencodedesktop-updater`（226M）
   - 仅当对应应用未在运行时删除；在运行则跳过

## 不做（仅建议）
- 下载文件夹安装包（1.36G）：用户确认软件装好后可自行删
- `powercfg /h off`（13.4G）：需管理员命令行，会关闭休眠/快速启动
- `C:\eSupport`（6.6G）：华硕驱动备份，删前需用户确认
- Windows 系统垃圾（Windows\Temp、更新缓存等）：建议用户用「设置→系统→存储→临时文件」处理
- Package Cache、pagefile.sys、Programs、.zcode：明确不动

## 验证
- 清理前后各跑一次 `df -h /c` 对比可用空间，向用户报告实际释放量
- 抽查 Temp/CrashDumps 剩余内容（应为被占用文件或空）