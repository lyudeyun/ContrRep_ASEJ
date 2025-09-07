img = imread('WechatIMG32.jpg');  % 替换为你的图片文件名

% 将图像转换为 double 类型以便处理
img = im2double(img);

% 分离 R, G, B 通道
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

% 设置判断为“红色”的条件（可根据实际情况微调）
redMask = (R > 0.6) & (G < 0.4) & (B < 0.4);

% 计算红色区域像素数和总像素数
redPixelCount = sum(redMask(:));
totalPixelCount = numel(R);

% 计算红色区域的占比
redRatio = redPixelCount / totalPixelCount;

% 输出结果
fprintf('红色区域占比: %.2f%%\n', redRatio * 100);

% 可选：显示红色掩码区域
% figure; imshow(redMask); title('Red Area Mask');