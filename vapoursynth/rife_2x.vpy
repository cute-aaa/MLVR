# RIFE 2x 补帧脚本 (PotPlayer VapourSynth)
# 将视频帧率提升 2 倍（如 30fps → 60fps）
import vapoursynth as vs
core = vs.core

# RIFE 补帧插件
from vsrife import rife

# PotPlayer 传入的视频流
clip = video_in

# RIFE 补帧 (2x)
# model 参数说明:
#   22 - RIFE v4.22 (推荐，通用模型)
#   23 - RIFE v4.23 (更新，可能更慢)
#   25 - RIFE v4.25 (最新，效果最好但最慢)
clip = rife(clip, model=22)

# 输出给 PotPlayer
clip.set_output()
