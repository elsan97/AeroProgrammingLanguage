/*
 * Aero Language V4 - НАСТОЯЩИЕ ОКНА WINDOWS
 * progname/progcode и gamename/gamecode создают РЕАЛЬНЫЕ ОКНА
 */

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <time.h>

#define MAX_VARS 2000
#define MAX_STRING 4096
#define MAX_CODE 100000
#define MAX_LINES 5000

// ==================== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ====================

typedef struct {
    char name[100];
    int type;
    union {
        long long int_val;
        double float_val;
        char str_val[MAX_STRING];
        int bool_val;
    } value;
} Variable;

Variable vars[MAX_VARS];
int var_count = 0;

char program_name[MAX_STRING] = "Aero Program";
char program_code[MAX_CODE] = "";
char program_output[MAX_CODE] = "";
char program_charset[MAX_STRING] = "UTF-8";
int is_game_mode = 0;
int has_program = 0;
UINT current_codepage = 65001; // UTF-8 по умолчанию

HWND hMainWindow = NULL;
HWND hOutputLabel = NULL;
HWND hOkButton = NULL;

// ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================

Variable* find_var(const char* name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(vars[i].name, name) == 0) return &vars[i];
    }
    return NULL;
}

Variable* create_var(const char* name, int type) {
    Variable* v = find_var(name);
    if (!v) v = &vars[var_count++];
    strcpy(v->name, name);
    v->type = type;
    return v;
}

double get_num(const char* p) {
    while (*p == ' ') p++;
    if (*p == '#') {
        Variable* v = find_var(p + 1);
        if (v) {
            if (v->type == 1) return v->value.int_val;
            if (v->type == 2) return v->value.float_val;
        }
        return 0;
    }
    return atof(p);
}

void get_str(const char* p, char* result) {
    while (*p == ' ') p++;
    if (*p == '"') {
        p++;
        const char* end = strchr(p, '"');
        if (end) {
            int len = end - p;
            strncpy(result, p, len);
            result[len] = '\0';
        } else strcpy(result, p);
    } else if (*p == '#') {
        Variable* v = find_var(p + 1);
        if (v) {
            if (v->type == 3) strcpy(result, v->value.str_val);
            else if (v->type == 1) sprintf(result, "%lld", v->value.int_val);
            else if (v->type == 2) sprintf(result, "%g", v->value.float_val);
            else strcpy(result, "null");
        } else strcpy(result, "[undefined]");
    } else strcpy(result, p);
}

void str_lower(char* dest, const char* src) {
    int i = 0;
    while (src[i]) { dest[i] = tolower(src[i]); i++; }
    dest[i] = '\0';
}

// Конвертация UTF-8 в Wide и обратно
int utf8_to_wide(const char* utf8, WCHAR* wide, int wide_size) {
    return MultiByteToWideChar(CP_UTF8, 0, utf8, -1, wide, wide_size);
}

int wide_to_utf8(const WCHAR* wide, char* utf8, int utf8_size) {
    return WideCharToMultiByte(CP_UTF8, 0, wide, -1, utf8, utf8_size, NULL, NULL);
}

// Добавить текст в вывод
void add_output(const char* text) {
    strcat(program_output, text);
    strcat(program_output, "\r\n");
}

// ==================== КОМАНДЫ ====================

void cmd_echo(const char* p) {
    char output[MAX_STRING] = "";
    const char* ptr = p;
    
    while (*ptr) {
        while (*ptr == ' ') ptr++;
        if (*ptr == '"') {
            ptr++;
            while (*ptr && *ptr != '"') {
                char ch[2] = {*ptr, '\0'};
                strcat(output, ch);
                ptr++;
            }
            if (*ptr == '"') ptr++;
        } else if (*ptr == '#') {
            char vname[100];
            int i = 0;
            ptr++;
            while (*ptr && *ptr != ' ' && *ptr != '{') {
                vname[i++] = *ptr++;
            }
            vname[i] = '\0';
            Variable* v = find_var(vname);
            if (v) {
                if (v->type == 1) {
                    char tmp[50];
                    sprintf(tmp, "%lld", v->value.int_val);
                    strcat(output, tmp);
                } else if (v->type == 3) {
                    strcat(output, v->value.str_val);
                }
            }
        } else {
            char ch[2] = {*ptr, '\0'};
            strcat(output, ch);
            ptr++;
        }
    }
    add_output(output);
}

void cmd_int(const char* p) {
    while (*p == ' ') p++;
    if (*p == '#') {
        char vname[100];
        sscanf(p, "#%s", vname);
        char* eq = strchr(p, '=');
        if (eq) {
            eq++;
            while (*eq == ' ') eq++;
            Variable* v = create_var(vname, 1);
            v->value.int_val = atoll(eq);
        }
    }
}

void cmd_str(const char* p) {
    while (*p == ' ') p++;
    if (*p == '#') {
        char vname[100];
        const char* eq = strstr(p, "=\"");
        if (eq) {
            sscanf(p, "#%s", vname);
            eq += 2;
            const char* end = strchr(eq, '"');
            if (end) {
                Variable* v = create_var(vname, 3);
                int len = end - eq;
                strncpy(v->value.str_val, eq, len);
                v->value.str_val[len] = '\0';
            }
        }
    }
}

void cmd_add(const char* p) {
    char a[100], b[100];
    sscanf(p, "%s %s", a, b);
    char r[100];
    sprintf(r, "%g", get_num(a) + get_num(b));
    add_output(r);
}

void cmd_sub(const char* p) {
    char a[100], b[100];
    sscanf(p, "%s %s", a, b);
    char r[100];
    sprintf(r, "%g", get_num(a) - get_num(b));
    add_output(r);
}

void cmd_mul(const char* p) {
    char a[100], b[100];
    sscanf(p, "%s %s", a, b);
    char r[100];
    sprintf(r, "%g", get_num(a) * get_num(b));
    add_output(r);
}

void cmd_div(const char* p) {
    char a[100], b[100];
    sscanf(p, "%s %s", a, b);
    double av = get_num(a), bv = get_num(b);
    if (bv != 0) {
        char r[100];
        sprintf(r, "%g", av / bv);
        add_output(r);
    } else add_output("[ERROR] Division by zero");
}

void cmd_random(const char* p) {
    static int seeded = 0;
    if (!seeded) { srand((unsigned)time(NULL)); seeded = 1; }
    int min = 0, max = 100;
    sscanf(p, "%d %d", &min, &max);
    char r[100];
    sprintf(r, "%d", rand() % (max - min + 1) + min);
    add_output(r);
}

void cmd_pause(const char* p) {
    add_output("Press any key...");
}

void cmd_clear(const char* p) {
    strcpy(program_output, "");
}

void cmd_date(const char* p) {
    time_t t = time(NULL);
    struct tm* tm = localtime(&t);
    char buf[100];
    strftime(buf, sizeof(buf), "%Y-%m-%d", tm);
    add_output(buf);
}

void cmd_time(const char* p) {
    time_t t = time(NULL);
    struct tm* tm = localtime(&t);
    char buf[100];
    strftime(buf, sizeof(buf), "%H:%M:%S", tm);
    add_output(buf);
}

void cmd_help(const char* p) {
    add_output("=== AERO LANGUAGE V4 ===");
    add_output("Syntax: {Aero}{progname}Name{|}{progcode}Code{|}{|}");
    add_output("Commands: echo, int, str, add, sub, mul, div, random");
    add_output("         pause, clear, date, time, help, charset");
}

void cmd_charset(const char* p) {
    char charset[100];
    get_str(p, charset);
    
    char charset_lower[100];
    str_lower(charset_lower, charset);
    
    if (strcmp(charset_lower, "utf-8") == 0 || strcmp(charset_lower, "utf8") == 0) {
        current_codepage = 65001;
        strcpy(program_charset, "UTF-8");
    }
    else if (strcmp(charset_lower, "cp1251") == 0 || strcmp(charset_lower, "windows-1251") == 0) {
        current_codepage = 1251;
        strcpy(program_charset, "CP1251");
    }
    else if (strcmp(charset_lower, "cp866") == 0 || strcmp(charset_lower, "dos") == 0) {
        current_codepage = 866;
        strcpy(program_charset, "CP866");
    }
    else if (strcmp(charset_lower, "koi8-r") == 0 || strcmp(charset_lower, "koi8r") == 0) {
        current_codepage = 20866;
        strcpy(program_charset, "KOI8-R");
    }
    else if (strcmp(charset_lower, "iso-8859-5") == 0 || strcmp(charset_lower, "iso8859-5") == 0) {
        current_codepage = 28595;
        strcpy(program_charset, "ISO-8859-5");
    }
    else if (strcmp(charset_lower, "ascii") == 0) {
        current_codepage = 1252;
        strcpy(program_charset, "ASCII");
    }
    else {
        // Пробуем установить указанную кодировку напрямую
        int cp = atoi(charset);
        if (cp > 0) {
            current_codepage = cp;
            strcpy(program_charset, charset);
        }
    }
    
    SetConsoleOutputCP(current_codepage);
    SetConsoleCP(current_codepage);
}

// ==================== ТАБЛИЦА КОМАНД ====================

typedef struct {
    const char* name;
    void (*func)(const char*);
} Command;

Command cmd_table[] = {
    {"echo", cmd_echo},
    {"int", cmd_int},
    {"str", cmd_str},
    {"add", cmd_add},
    {"sub", cmd_sub},
    {"mul", cmd_mul},
    {"div", cmd_div},
    {"random", cmd_random},
    {"pause", cmd_pause},
    {"clear", cmd_clear},
    {"date", cmd_date},
    {"time", cmd_time},
    {"help", cmd_help},
    {"charset", cmd_charset},
};

int cmd_count = sizeof(cmd_table) / sizeof(cmd_table[0]);

// ==================== ПАРСЕР ====================

void execute_command(const char* cmd, const char* params) {
    char cmd_lower[100];
    str_lower(cmd_lower, cmd);
    
    for (int i = 0; i < cmd_count; i++) {
        if (strcmp(cmd_table[i].name, cmd_lower) == 0) {
            cmd_table[i].func(params);
            return;
        }
    }
}

void parse_code(const char* code) {
    char* code_copy = malloc(strlen(code) + 1);
    strcpy(code_copy, code);
    
    char* ptr = code_copy;
    
    while (*ptr) {
        // Пропускаем пробелы и переводы строк
        while (*ptr == ' ' || *ptr == '\n' || *ptr == '\r') ptr++;
        if (!*ptr) break;
        
        // Ищем {cmd}params{|}
        if (*ptr == '{') {
            ptr++;
            
            // Извлекаем команду
            char cmd[100] = "";
            int i = 0;
            while (*ptr && *ptr != '}' && i < 99) {
                cmd[i++] = *ptr++;
            }
            cmd[i] = '\0';
            
            if (*ptr == '}') ptr++;
            
            // Извлекаем параметры до {|}
            char params[MAX_STRING] = "";
            i = 0;
            while (*ptr && !(*ptr == '{' && *(ptr+1) == '|' && *(ptr+2) == '}') && i < MAX_STRING-1) {
                params[i++] = *ptr++;
            }
            params[i] = '\0';
            
            // Пропускаем {|}
            if (*ptr == '{' && *(ptr+1) == '|' && *(ptr+2) == '}') {
                ptr += 3;
            }
            
            // Выполняем команду
            execute_command(cmd, params);
        } else {
            ptr++;
        }
    }
    
    free(code_copy);
}

// ==================== ОКНО WINDOWS ====================

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_COMMAND:
            if ((HWND)lParam == hOkButton) {
                PostQuitMessage(0);
            }
            break;
            
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
            
        default:
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    return 0;
}

void CreateProgramWindow() {
    // Регистрация класса окна
    WNDCLASS wc = {0};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = "AeroWindowClass";
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    RegisterClass(&wc);
    
    // Размеры окна
    int width = is_game_mode ? GetSystemMetrics(SM_CXSCREEN) : 600;
    int height = is_game_mode ? GetSystemMetrics(SM_CYSCREEN) : 400;
    int x = is_game_mode ? 0 : (GetSystemMetrics(SM_CXSCREEN) - width) / 2;
    int y = is_game_mode ? 0 : (GetSystemMetrics(SM_CYSCREEN) - height) / 2;
    
    DWORD style = is_game_mode ? WS_POPUP | WS_VISIBLE : WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_VISIBLE;
    
    // Создание окна
    hMainWindow = CreateWindow(
        "AeroWindowClass",
        program_name,
        style,
        x, y, width, height,
        NULL, NULL, GetModuleHandle(NULL), NULL
    );
    
    if (!hMainWindow) {
        MessageBox(NULL, "Failed to create window", "Error", MB_ICONERROR);
        return;
    }
    
    // Создание текстового поля вывода
    HWND hEdit = CreateWindow(
        "EDIT",
        program_output,
        WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE | ES_READONLY,
        10, 10, width - 20, height - 60,
        hMainWindow, NULL, GetModuleHandle(NULL), NULL
    );
    
    // Создание кнопки OK
    hOkButton = CreateWindow(
        "BUTTON",
        "OK",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        (width - 100) / 2, height - 45, 100, 30,
        hMainWindow, NULL, GetModuleHandle(NULL), NULL
    );
    
    // Установка шрифта
    HFONT hFont = CreateFont(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, "Consolas");
    SendMessage(hEdit, WM_SETFONT, (WPARAM)hFont, TRUE);
    
    // Показать окно
    ShowWindow(hMainWindow, SW_SHOW);
    UpdateWindow(hMainWindow);
    
    // Цикл сообщений
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

// ==================== ПАРСЕР ФАЙЛА ====================

void parse_file(const char* filename) {
    FILE* f = fopen(filename, "r");
    if (!f) {
        printf("[ERROR] Cannot open file: %s\n", filename);
        return;
    }
    
    char line[MAX_STRING];
    char current_cmd[100] = "";
    char current_params[MAX_STRING] = "";
    int in_progcode = 0;
    int brace_depth = 0;
    
    while (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = '\0';
        line[strcspn(line, "\r")] = '\0';
        
        char* ptr = line;
        
        while (*ptr) {
            if (*ptr == '{') {
                brace_depth++;
                ptr++;
                
                // Извлекаем команду
                char cmd[100] = "";
                int i = 0;
                while (*ptr && *ptr != '}' && i < 99) {
                    cmd[i++] = *ptr++;
                }
                cmd[i] = '\0';
                
                if (*ptr == '}') {
                    ptr++;
                    brace_depth--;
                }
                
                // Обработка команд программы/игры
                char cmd_lower[100];
                str_lower(cmd_lower, cmd);
                
                if (strcmp(cmd_lower, "aero") == 0 || strcmp(cmd_lower, "progname") == 0) {
                    // Извлекаем название
                    char name[MAX_STRING] = "";
                    i = 0;
                    while (*ptr && !(*ptr == '{' && *(ptr+1) == '|')) {
                        if (*ptr != ' ' || i > 0) name[i++] = *ptr;
                        ptr++;
                    }
                    name[i] = '\0';
                    // Убираем пробелы в конце
                    while (i > 0 && name[i-1] == ' ') name[--i] = '\0';
                    
                    strcpy(program_name, name);
                    has_program = 1;
                }
                else if (strcmp(cmd_lower, "game") == 0 || strcmp(cmd_lower, "gamename") == 0) {
                    char name[MAX_STRING] = "";
                    i = 0;
                    while (*ptr && !(*ptr == '{' && *(ptr+1) == '|')) {
                        if (*ptr != ' ' || i > 0) name[i++] = *ptr;
                        ptr++;
                    }
                    name[i] = '\0';
                    while (i > 0 && name[i-1] == ' ') name[--i] = '\0';
                    
                    strcpy(program_name, name);
                    is_game_mode = 1;
                    has_program = 1;
                }
                else if (strcmp(cmd_lower, "progcode") == 0 || strcmp(cmd_lower, "gamecode") == 0) {
                    in_progcode = 1;
                    ptr++;
                }
                else if (strcmp(cmd_lower, "|") == 0) {
                    // {|} - закрывающий тег
                    if (in_progcode) {
                        in_progcode = 0;
                    }
                    ptr += 2;
                }
                else if (in_progcode) {
                    // Добавляем команду в код программы
                    strcat(program_code, "{");
                    strcat(program_code, cmd);
                    strcat(program_code, "}");
                    
                    // Извлекаем параметры
                    char params[MAX_STRING] = "";
                    i = 0;
                    while (*ptr && !(*ptr == '{' && *(ptr+1) == '|' && *(ptr+2) == '}')) {
                        params[i++] = *ptr++;
                    }
                    params[i] = '\0';
                    
                    strcat(program_code, params);
                    
                    // Пропускаем {|}
                    if (*ptr == '{' && *(ptr+1) == '|' && *(ptr+2) == '}') {
                        strcat(program_code, "{|}");
                        ptr += 3;
                    }
                }
            } else {
                ptr++;
            }
        }
    }
    
    fclose(f);
}

// ==================== MAIN ====================

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // Установка UTF-8 по умолчанию
    SetConsoleOutputCP(65001);
    SetConsoleCP(65001);
    current_codepage = 65001;
    
    // Получаем аргументы командной строки
    int argc;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    
    if (argc < 2) {
        MessageBox(NULL, 
            "Aero Language V4 Interpreter\n\n"
            "Usage: AeroInterpreter_V4.exe <file.aer>\n\n"
            "Syntax:\n"
            "{Aero}{progname}Name{|}{progcode}Commands{|}{|}\n"
            "{game}{gamename}Name{|}{gamecode}Commands{|}{|}",
            "Aero V4",
            MB_OK | MB_ICONINFORMATION
        );
        LocalFree(argv);
        return 0;
    }
    
    // Конвертируем путь к файлу
    char filename[MAX_PATH];
    WideCharToMultiByte(CP_UTF8, 0, argv[1], -1, filename, MAX_PATH, NULL, NULL);
    LocalFree(argv);
    
    // Парсим файл
    parse_file(filename);
    
    // Если есть программа - выполняем
    if (has_program && strlen(program_code) > 0) {
        parse_code(program_code);
    }
    
    // Создаём окно
    if (has_program) {
        CreateProgramWindow();
    } else {
        // Если нет программы - выводим в консоль
        printf("%s\n", program_output);
        printf("\nPress Enter to exit...");
        getchar();
    }
    
    return 0;
}