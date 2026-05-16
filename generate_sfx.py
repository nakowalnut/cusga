import wave
import math
import struct
import random
import os

# 确保输出目录存在
OUTPUT_DIR = 'assets/audio'
os.makedirs(OUTPUT_DIR, exist_ok=True)

SAMPLE_RATE = 44100

def save_wav(filename, samples):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1) # 单声道
        wav_file.setsampwidth(2) # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        for s in samples:
            # 限制在 -1 到 1 之间，转换成 16-bit int
            val = int(max(-1.0, min(1.0, s)) * 32767)
            # pack as little-endian short
            wav_file.writeframesraw(struct.pack('<h', val))
    print(f"已生成音效: {filepath}")

def generate_jump():
    """生成跳跃音效：频率快速上升的波形"""
    samples = []
    freq = 200.0  # 起始频率
    duration = 0.25
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        # 频率随时间非线性递增
        freq += 0.05
        # 使用方波让声音更复古("马里奥跳"的感觉)
        t = i / SAMPLE_RATE
        val = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        # 添加包络线 (淡出效果)
        envelope = 1.0 - (i / steps)
        samples.append(val * envelope * 0.3)
    return samples

def generate_hit():
    """生成受击音效：白噪声混合音调急剧下降"""
    samples = []
    freq = 150.0  # 起始频率
    duration = 0.15
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        freq -= 0.1
        freq = max(10, freq)
        t = i / SAMPLE_RATE
        # 方波 + 随机噪声 (表现出受击的破碎感)
        base_wave = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        noise = random.uniform(-1.0, 1.0)
        
        envelope = math.pow(1.0 - (i / steps), 2) # 指数衰减更自然
        val = (base_wave * 0.4 + noise * 0.6) * envelope
        samples.append(val * 0.4)
    return samples

def apply_lowpass_6db(samples, cutoff_hz):
    """简单一阶低通滤波（6dB/oct），使音效不那么刺耳"""
    if len(samples) == 0:
        return samples
    dt = 1.0 / SAMPLE_RATE
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    alpha = dt / (rc + dt)
    out = [0.0] * len(samples)
    out[0] = samples[0]
    for i in range(1, len(samples)):
        out[i] = out[i-1] + alpha * (samples[i] - out[i-1])
    return out

def generate_attack_slash():
    """挥剑斩击音效：中频噪声扫过 + 轻微金属嗡声"""
    samples = []
    freq = 1200.0   # 起始中心频率较高，模拟"咻"声
    duration = 0.18
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        progress = i / steps
        noise = random.uniform(-1.0, 1.0)
        t = i / SAMPLE_RATE
        # 音调快速下坠，模拟刀刃划过空气
        current_freq = freq * (1.0 - progress * 0.85)
        tone = math.sin(2.0 * math.pi * current_freq * t)
        # 混合噪声与音调，噪声占比更高更有"切割感"
        mix = tone * 0.25 + noise * 0.75
        envelope = math.pow(1.0 - progress, 2.5)
        samples.append(mix * envelope * 0.45)
    return apply_lowpass_6db(samples, 6000)

def generate_attack_slash2():
    """挥剑斩击变体：更尖锐、更快的双音调扫过"""
    samples = []
    duration = 0.12
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        progress = i / steps
        noise = random.uniform(-1.0, 1.0)
        t = i / SAMPLE_RATE
        # 两个谐波叠加，产生更丰富的泛音
        f1 = 1800.0 * (1.0 - progress * 0.9)
        f2 = 2400.0 * (1.0 - progress * 0.8)
        tone = math.sin(2.0 * math.pi * f1 * t) * 0.3 + math.sin(2.0 * math.pi * f2 * t) * 0.15
        envelope = math.pow(1.0 - progress, 3.0)
        samples.append((tone + noise * 0.6) * envelope * 0.4)
    return apply_lowpass_6db(samples, 8000)

def generate_attack_heavy():
    """重击/锤击音效：低频冲击 + 噪声爆炸 + 残响"""
    samples = []
    duration = 0.45
    steps = int(SAMPLE_RATE * duration)
    impact_dur = 0.03        # 冲击瞬间
    impact_steps = int(SAMPLE_RATE * impact_dur)
    tail_steps = steps - impact_steps
    for i in range(steps):
        progress = i / steps
        noise = random.uniform(-1.0, 1.0)
        t = i / SAMPLE_RATE
        if i < impact_steps:
            # 冲击瞬间：低频 + 大量噪声
            bass = math.sin(2.0 * math.pi * 60.0 * t)  # 猛烈的低频
            hit_env = 1.0 - (i / impact_steps)
            samples.append((bass * 0.7 + noise * 0.3) * hit_env * 0.9)
        else:
            # 余韵部分：低沉衰减
            tail_progress = (i - impact_steps) / tail_steps
            rumble = math.sin(2.0 * math.pi * (45.0 - tail_progress * 20.0) * t)
            tail_env = math.pow(1.0 - tail_progress, 1.8)
            samples.append((rumble * 0.5 + noise * 0.5) * tail_env * 0.45)
    return apply_lowpass_6db(samples, 2000)

def generate_attack_light():
    """轻攻击/匕首音效：快速高频嘶声"""
    samples = []
    duration = 0.08
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        progress = i / steps
        noise = random.uniform(-1.0, 1.0)
        t = i / SAMPLE_RATE
        f = 2500.0 * (1.0 - progress * 0.6)
        tone = math.sin(2.0 * math.pi * f * t) * 0.2
        envelope = math.pow(1.0 - progress, 4.0)
        samples.append((tone + noise * 0.8) * envelope * 0.3)
    return apply_lowpass_6db(samples, 10000)

def generate_attack_combo():
    """连击音效：三段递增强化的短击"""
    samples = []
    hit_dur = 0.07        # 每击长度
    gap_dur = 0.04        # 间隙
    total_dur = hit_dur * 3 + gap_dur * 2
    steps = int(SAMPLE_RATE * total_dur)
    hits = [
        {"start": 0.0,              "freq": 800.0,  "amp": 0.35},
        {"start": hit_dur + gap_dur, "freq": 1100.0, "amp": 0.40},
        {"start": (hit_dur + gap_dur) * 2, "freq": 1400.0, "amp": 0.50},
    ]
    for i in range(steps):
        t = i / SAMPLE_RATE
        val = 0.0
        for hit in hits:
            hit_t = t - hit["start"]
            if 0.0 <= hit_t < hit_dur:
                progress = hit_t / hit_dur
                noise = random.uniform(-1.0, 1.0)
                tone = math.sin(2.0 * math.pi * hit["freq"] * (1.0 - progress * 0.5) * t)
                envelope = math.pow(1.0 - progress, 2.5)
                val += (tone * 0.3 + noise * 0.7) * envelope * hit["amp"]
        samples.append(val)
    return apply_lowpass_6db(samples, 8000)

def generate_attack_spear():
    """长矛突刺音效：拉长的集中气流通音"""
    samples = []
    duration = 0.22
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        progress = i / steps
        noise = random.uniform(-1.0, 1.0)
        t = i / SAMPLE_RATE
        # 频率集中在中高频，有"穿刺"感
        f = 1500.0 - progress * 400.0
        tone = math.sin(2.0 * math.pi * f * t) * 0.35
        # 前半段渐强，后半段衰减，模拟"刺出→命中"
        if progress < 0.3:
            envelope = progress / 0.3  # 蓄力阶段
        else:
            envelope = math.pow(1.0 - (progress - 0.3) / 0.7, 2.0)
        samples.append((tone + noise * 0.5) * envelope * 0.4)
    return apply_lowpass_6db(samples, 9000)

def generate_attack_crit():
    """暴击音效：明亮金属撞击 + 谐波共鸣"""
    samples = []
    duration = 0.3
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        progress = i / steps
        t = i / SAMPLE_RATE
        noise = random.uniform(-1.0, 1.0)
        # 多个高频谐波叠加，产生金属感
        f_base = 2200.0
        f2 = f_base * 2.0
        f3 = f_base * 3.0
        tone = (math.sin(2.0 * math.pi * f_base * t) * 0.5 +
                math.sin(2.0 * math.pi * f2 * t) * 0.25 +
                math.sin(2.0 * math.pi * f3 * t) * 0.12)
        # 快速衰减的金属音 + 冲击噪声
        env_tone = math.pow(1.0 - progress, 1.2)  # 金属音衰减较慢
        env_noise = math.pow(1.0 - progress, 4.0)  # 噪声快速消退
        val = tone * env_tone * 0.35 + noise * env_noise * 0.5
        samples.append(val)
    return apply_lowpass_6db(samples, 12000)

def generate_attack_charge():
    """蓄力攻击音效：频率逐渐升高的嗡鸣 → 爆发"""
    samples = []
    charge_dur = 0.35   # 蓄力阶段
    burst_dur = 0.12    # 爆发阶段
    total_dur = charge_dur + burst_dur
    steps = int(SAMPLE_RATE * total_dur)
    for i in range(steps):
        t = i / SAMPLE_RATE
        progress = i / steps
        noise = random.uniform(-1.0, 1.0)
        if t < charge_dur:
            # 蓄力：频率从低到高上升
            charge_progress = t / charge_dur
            f = 200.0 + charge_progress * 1800.0  # 200Hz → 2000Hz
            tone = 1.0 if math.sin(2.0 * math.pi * f * t) > 0 else -1.0  # 方波更有力度
            # 加入少量噪声模拟能量聚集
            val = tone * 0.3 + noise * 0.15 * charge_progress
        else:
            # 爆发：强大噪声冲击后快速衰减
            burst_t = t - charge_dur
            burst_progress = burst_t / burst_dur
            bass = math.sin(2.0 * math.pi * 55.0 * t) * 0.6
            val = (bass + noise * 0.7) * math.pow(1.0 - burst_progress, 3.0) * 0.7
        samples.append(val)
    return apply_lowpass_6db(samples, 4000)

def generate_attack_bow():
    """弓箭射击音效：弓弦弹射声（极短高频脉冲 + 震颤衰减）"""
    samples = []
    duration = 0.25
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        progress = i / steps
        t = i / SAMPLE_RATE
        noise = random.uniform(-1.0, 1.0)
        # 弓弦震颤频率
        f_string = 2000.0 * math.pow(1.0 - progress, 0.6)  # 频率逐渐下降
        string_vib = math.sin(2.0 * math.pi * f_string * t)
        # 极短脉冲冲击
        pulse_len = 0.01
        pulse = 1.0 if t < pulse_len else 0.0
        envelope = math.pow(1.0 - progress, 4.0)
        val = (string_vib * 0.35 + noise * 0.2 + pulse * 0.6) * envelope
        samples.append(val * 0.4)
    return apply_lowpass_6db(samples, 10000)

def generate_attack_blunt():
    """钝器打击音效：短促有力的"砰"声（棍棒、钝器）"""
    samples = []
    duration = 0.15
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        progress = i / steps
        t = i / SAMPLE_RATE
        noise = random.uniform(-1.0, 1.0)
        # 低频重击
        bass = math.sin(2.0 * math.pi * 80.0 * t)
        # 极快衰减
        envelope = math.pow(1.0 - progress, 5.0)
        val = (bass * 0.7 + noise * 0.3) * envelope * 0.7
        samples.append(val)
    return apply_lowpass_6db(samples, 1500)

def generate_attack_sword_clash():
    """剑刃碰撞音效：金属叮当声 + 延音余韵"""
    samples = []
    duration = 0.3
    steps = int(SAMPLE_RATE * duration)
    # 多个泛音频率组合模拟金属碰撞
    harmonics = [(3000.0, 0.5, 2.5), (4500.0, 0.3, 3.5), (5500.0, 0.15, 5.0)]
    for i in range(steps):
        progress = i / steps
        t = i / SAMPLE_RATE
        noise = random.uniform(-1.0, 1.0)
        val = 0.0
        for freq, amp, decay_pow in harmonics:
            current_freq = freq * (1.0 - progress * 0.3)
            val += math.sin(2.0 * math.pi * current_freq * t) * amp * math.pow(1.0 - progress, decay_pow)
        val += noise * math.pow(1.0 - progress, 6.0) * 0.3
        samples.append(val * 0.4)
    return apply_lowpass_6db(samples, 14000)

def generate_dash():
    """生成冲刺/闪避音效：拉长且平滑的嘶嘶声"""
    samples = []
    duration = 0.3
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        noise = random.uniform(-1.0, 1.0)
        # 包络线先上升后下降
        progress = i / steps
        envelope = math.sin(progress * math.pi)
        samples.append(noise * envelope * 0.25)
    return samples

def generate_ui_select():
    """生成UI选择音效：非常短促的高频哔声"""
    samples = []
    duration = 0.05
    steps = int(SAMPLE_RATE * duration)
    freq = 880.0 # A5音高
    for i in range(steps):
        t = i / SAMPLE_RATE
        val = math.sin(2 * math.pi * freq * t)
        envelope = 1.0 - (i / steps)
        samples.append(val * envelope * 0.2)
    return samples

def generate_ui_submit():
    """生成UI确认音效：两声连续的高频哔声"""
    samples = []
    duration = 0.15
    steps = int(SAMPLE_RATE * duration)
    for i in range(steps):
        t = i / SAMPLE_RATE
        # 时间过半时提升音调
        freq = 880.0 if i < steps/2 else 1108.0 # A5 to C#6
        val = math.sin(2 * math.pi * freq * t)
        
        # 为每段声音做一个小的包络
        half_steps = steps / 2
        local_i = i % half_steps
        envelope = 1.0 - (local_i / half_steps)
        
        samples.append(val * envelope * 0.2)
    return samples

if __name__ == "__main__":
    print("开始基于代码合成攻击音效...")
    save_wav('attack_slash.wav', generate_attack_slash())
    save_wav('attack_slash2.wav', generate_attack_slash2())
    save_wav('attack_spear.wav', generate_attack_spear())
    save_wav('attack_bow.wav', generate_attack_bow())
    save_wav('attack_heavy.wav', generate_attack_heavy())
    save_wav('attack_light.wav', generate_attack_light())
    save_wav('attack_combo.wav', generate_attack_combo())
    save_wav('attack_crit.wav', generate_attack_crit())
    save_wav('attack_charge.wav', generate_attack_charge())
    save_wav('attack_blunt.wav', generate_attack_blunt())
    save_wav('attack_sword_clash.wav', generate_attack_sword_clash())
    print("生成完毕！请查看 assets/audio 目录，Godot 会自动将它们导入。")