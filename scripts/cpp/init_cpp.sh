#!/usr/bin/env bash

echo "=========================================="
echo "    🚀 TẠO DỰ ÁN C++ (INTERACTIVE)      "
echo "=========================================="

# 1. Thu thập thông tin cấu hình cơ bản
read -p "Tên dự án [App]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-App}

read -p "Loại dự án (1: Executable, 2: Library) [1]: " PROJ_TYPE
PROJ_TYPE=${PROJ_TYPE:-1}

read -p "Tên file entry point (vd: src/main.cpp) [main.cpp]: " ENTRY_POINT
ENTRY_POINT=${ENTRY_POINT:-main.cpp}

read -p "Chuẩn C++ (11, 14, 17, 20, 23) [17]: " CPP_STD
CPP_STD=${CPP_STD:-17}

# 2. Quét và chọn Compiler
echo -e "\n🔍 Đang tìm kiếm C++ compiler trên máy..."
AVAILABLE_COMPILERS=()

# Dùng compgen để quét toàn bộ lệnh trong PATH khớp với clang++ hoặc g++ (bao gồm cả các bản có số version phía sau)
while read -r cmd; do
    AVAILABLE_COMPILERS+=("$cmd")
done < <(compgen -c | grep -E '^(clang\+\+|g\+\+)(-[0-9]+)?$' | sort -u)

if [ ${#AVAILABLE_COMPILERS[@]} -eq 0 ]; then
    echo "⚠️ Không tìm thấy compiler nào. Mặc định dùng clang++."
    CXX_COMP="clang++"
else
    echo "👉 Vui lòng chọn Compiler:"
    select opt in "${AVAILABLE_COMPILERS[@]}" "Nhập thủ công"; do
        if [[ "$opt" == "Nhập thủ công" ]]; then
            read -p "Nhập tên compiler C++ (vd: clang++): " CXX_COMP
            CXX_COMP=${CXX_COMP:-clang++}
            break
        elif [[ -n "$opt" ]]; then
            CXX_COMP="$opt"
            break
        else
            echo "❌ Lựa chọn không hợp lệ, vui lòng chọn lại."
        fi
    done
fi

# Tự động suy luận C compiler tương ứng
if [[ "$CXX_COMP" == *"clang"* ]]; then
    C_COMP="${CXX_COMP/clang++/clang}"
elif [[ "$CXX_COMP" == *"g++"* ]]; then
    C_COMP="${CXX_COMP/g++/gcc}"
else
    C_COMP="gcc"
fi

echo -e "\n✅ Khởi tạo dự án '$PROJECT_NAME' với $CXX_COMP ($C_COMP)...\n"

# 3. Tạo cấu trúc thư mục
mkdir -p "$PROJECT_NAME" && cd "$PROJECT_NAME" || exit
mkdir -p "$(dirname "$ENTRY_POINT")"

# 4. Phân nhánh tạo mã nguồn & cấu hình CMake
if [ "$PROJ_TYPE" == "1" ]; then
    cat << EOF > "$ENTRY_POINT"
#include <iostream>

int main() {
    std::cout << "Hello from $PROJECT_NAME (Executable)!" << std::endl;
    return 0;
}
EOF
    CMAKE_TARGET_CMD="add_executable($PROJECT_NAME $ENTRY_POINT)"
else
    cat << EOF > "$ENTRY_POINT"
#include <iostream>

void hello_$PROJECT_NAME() {
    std::cout << "Hello from $PROJECT_NAME (Library)!" << std::endl;
}
EOF
    CMAKE_TARGET_CMD="add_library($PROJECT_NAME STATIC $ENTRY_POINT)"
fi

# 5. Tạo CMakeLists.txt
cat << EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project($PROJECT_NAME VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD $CPP_STD)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

$CMAKE_TARGET_CMD

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options($PROJECT_NAME PRIVATE -Wall -Wextra -Wpedantic)
endif()
EOF

# 6. Tạo build.sh (Cho Bash/Zsh)
cat << EOF > build.sh
#!/usr/bin/env bash
rm -rf build
cmake -B build -S . -G Ninja -DCMAKE_CXX_COMPILER="$CXX_COMP" -DCMAKE_C_COMPILER="$C_COMP"
ln -sf build/compile_commands.json .
cmake --build build

if [[ "\$1" == "-r" || "\$1" == "--run" ]]; then
    if [ "$PROJ_TYPE" == "1" ]; then
        echo -e "\n🚀 CHẠY CHƯƠNG TRÌNH...\n"
        ./build/$PROJECT_NAME
    else
        echo -e "\n⚠️ Dự án này là Library, không thể chạy trực tiếp."
    fi
fi
EOF

# 7. Tạo build.fish (Cho Fish Shell)
cat << EOF > build.fish
#!/usr/bin/env fish
rm -rf build
cmake -B build -S . -G Ninja -DCMAKE_CXX_COMPILER="$CXX_COMP" -DCMAKE_C_COMPILER="$C_COMP"
ln -sf build/compile_commands.json .
cmake --build build

if contains -- "-r" \$argv; or contains -- "--run" \$argv
    if test "$PROJ_TYPE" = "1"
        echo -e "\n🚀 CHẠY CHƯƠNG TRÌNH...\n"
        ./build/$PROJECT_NAME
    else
        echo -e "\n⚠️ Dự án này là Library, không thể chạy trực tiếp."
    end
end
EOF

# 8. File bỏ qua của Git
cat << EOF > .gitignore
build/
compile_commands.json
.cache/
EOF

chmod +x build.sh build.fish

echo "✅ Hoàn tất! Cấu trúc dự án đã sẵn sàng."
echo "👉 Chuyển vào dự án: cd $PROJECT_NAME"
echo "👉 Dịch mã nguồn:    ./build.sh (hoặc ./build.fish)"

