import base64
import os
import re
import sys

# Справочники
S_MAP = {20150:'Кара', 20020:'Смайт', 20030:'Вдох', 20040:'Спринт', 20050:'Лужа', 20060:'Щит', 20070:'Оцепа', 20080:'Очищ', 20090:'Флейм', 20100:'Флик', 20110:'Прибытие', 20120:'Отомщ'}
R_MAP = {1: 'EXP', 2: 'MID', 3: 'ROAM', 4: 'JNG', 5: 'GOLD'}
G_MAP = {0: 'Нет', 1: 'Муж', 2: 'Жен'}
M_MAP = {1: 'MVP', 2: 'GOLD', 3: 'SILVER', 4: 'BRONZE'}

def rv(d, o):
    v, s = 0, 0
    while True:
        if o >= len(d): return 0, o
        b = d[o]; o += 1
        v |= (b & 0x7f) << s
        if not (b & 0x80): break
        s += 7
    return v, o

def parse_file(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"Ошибка: Файл {input_path} не найден.")
        return

    data = base64.b64decode(open(input_path, 'rb').read())
    
    # Поиск игроков
    sts = []
    for i in range(len(data)-3):
        if data[i] == 0x4d:
            l = data[i+1]
            if 2 < l < 30:
                try:
                    n = data[i+2:i+2+l].decode('utf-8')
                    if n.isprintable(): sts.append({'n': n, 's': i})
                except: pass
    sts.sort(key=lambda x: x['s'])
    ms = [m.start() for m in re.finditer(b'\x70\x50', data)]
    
    with open(output_path, 'w', encoding='utf-8') as out:
        out.write(f"ОТЧЕТ (КДА ИЗ БЛОКА ПРЕДМЕТОВ): {os.path.basename(input_path)}\n")
        out.write("="*110 + "\n\n")
        
        for i, ply in enumerate(sts):
            po = sts[i-1]['s'] if i > 0 else 0
            tm = next((m for m in ms if po < m < ply['s']), None)
            e = sts[i+1]['s'] if i+1 < len(sts) else len(data)
            p_block = data[ply['s']:e]
            
            # ID из 0x0E
            name_len = data[ply['s']+1]
            idx_0e = ply['s'] + 2 + name_len
            p_id_0e = 0
            if idx_0e < len(data) and data[idx_0e] == 0x0e:
                p_id_0e, _ = rv(data, idx_0e + 1)

            # Поля 0x0F
            f = {}; c = 0
            while c < len(p_block)-1:
                if p_block[c] == 0x0f:
                    fid = p_block[c+1]; v, nc = rv(p_block, c+2); f[fid] = v; c = nc
                else: c += 1
            
            # Предметы и КДА (новая логика)
            its = []; hid = 0; pk, pd, pa, plvl = 0, 0, 0, 0
            if tm is not None:
                cur = tm + 4
                while cur < len(data)-2:
                    v, nc = rv(data, cur)
                    its.append(v)
                    if data[nc] == 1: # Завершение списка предметов
                        # После 01: [1 byte unknown], 02, ID, 03, K, 04, D, 05, A, 06, Lvl
                        ptr = nc + 2 # Пропускаем 01 и непонятный байт
                        if ptr < len(data) and data[ptr] == 2:
                            hid, ptr = rv(data, ptr + 1)
                        if ptr < len(data) and data[ptr] == 3:
                            pk, ptr = rv(data, ptr + 1)
                        if ptr < len(data) and data[ptr] == 4:
                            pd, ptr = rv(data, ptr + 1)
                        if ptr < len(data) and data[ptr] == 5:
                            pa, ptr = rv(data, ptr + 1)
                        if ptr < len(data) and data[ptr] == 6:
                            plvl, ptr = rv(data, ptr + 1)
                        break
                    cur = nc + 1
            
            tg = f.get(82, 0) + f.get(86, 0) + f.get(87, 0)
            th = f.get(84, 0) + f.get(85, 0)
            
            out.write(f"ИГРОК: {ply['n']:20} | ID (0x0E): {p_id_0e:<12} | ГЕРОЙ ID: {hid:<3}\n")
            out.write(f"  КДА: {pk}/{pd}/{pa} (Уровень: {plvl}) | МЕДАЛЬ: {M_MAP.get(f.get(18,0), str(f.get(18,0))):7}\n")
            out.write(f"  УРОН: Герои: {f.get(19, 0):<7} Башни: {f.get(20, 0):<7} Получ: {f.get(21, 0)}\n")
            out.write(f"  ЗОЛОТО: Всего: {tg:<7} (Лес: {f.get(82, 0)}, Уб: {f.get(86, 0)}, Кр: {f.get(87, 0)})\n")
            out.write(f"  РОЛЬ: Поиск: {R_MAP.get(f.get(76,0), str(f.get(76,0))):<5} / Игра: {R_MAP.get(f.get(77,0), str(f.get(77,0))):<5}\n")
            out.write(f"  ПРОЧЕЕ: Клан: {f.get(30, 0):<10} | Лобби: {f.get(34, 0):<15} | Хил: {th}\n")
            out.write(f"  ПРЕДМЕТЫ: {its}\n")
            out.write("-" * 100 + "\n\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        # Для автоматического запуска по умолчанию
        parse_file('com.mobile.legends/files/dragon2017/FightHistory/His-23984353-489385184114808787', 'report_489_new.txt')
        parse_file('com.mobile.legends/files/dragon2017/FightHistory/His-23984353-441728884128417111', 'report_441_new.txt')
    else:
        parse_file(sys.argv[1], "report_output.txt")
