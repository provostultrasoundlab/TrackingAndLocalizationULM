function MatrixRGB=MergeImageBounds(Image1, colormap1, caxis1, ...
    Image2, colormap2, caxis2, C)

colormap1 = colormap(colormap1);
colormap2=colormap(colormap2);

Min1 = caxis1(1);
Min2=caxis2(1);
Max1 = caxis1(2);
Max2=caxis2(2);

% Image1(Image1==0)=NaN;
Image2(Image2==0)=NaN;

Transparency = max(0, min(1, C * Image1));
Transparency(isnan(Image2)) = 0.0;
Transparency(Image1==0) = 0.0;

Transparency(isnan(Image2)) = 0;
Transparency(Transparency>1) = 1;
Transparency(Transparency<0) = 0;
Transparency(isnan(Transparency)) = 0;

Image1(isnan(Image1)) = Min1;
Image2(isnan(Image2)) = Min2;

Ni = size(Image1,1);
Nj = size(Image1,2);

Image1(Image1<Min1)=Min1;
Image1(Image1>Max1)=Max1;

Image2(Image2<Min2)=Min2;
Image2(Image2>Max2)=Max2;

min1 = min(min(Image1(:)), Min1);
min2 = min(min(Image2(:)), Min2);
max1 = max(max(Image1(:)), Max1);
max2 = max(max(Image2(:)), Max2);

J1 = colormap1;
J2 = colormap2;

SizeColormap1 = size(J1,1);
SizeColormap2 = size(J2,1);

% Rescaling the images between 0 and 255 (if size of colormap is 256)
Image1 = round((Image1 - min1)/(max1 - min1 + 1e-6)*(SizeColormap1-1)) + 1;
Image2 = round((Image2 - min2)/(max2 - min2 + 1e-6)*(SizeColormap2-1)) + 1;

R1 = J1(:,1);
G1 = J1(:,2);
B1 = J1(:,3);

R2 = J2(:,1);
G2 = J2(:,2);
B2 = J2(:,3);

MatrixR1 = R1(Image1);
MatrixG1 = G1(Image1);
MatrixB1 = B1(Image1);

MatrixR2 = R2(Image2);
MatrixG2 = G2(Image2);
MatrixB2 = B2(Image2);

MatrixR = MatrixR1 + Transparency.*(MatrixR2-MatrixR1);
MatrixG = MatrixG1 + Transparency.*(MatrixG2-MatrixG1);
MatrixB = MatrixB1 + Transparency.*(MatrixB2-MatrixB1);

MatrixRGB = zeros(Ni,Nj,3);
MatrixRGB(:,:,1) = MatrixR;
MatrixRGB(:,:,2) = MatrixG;
MatrixRGB(:,:,3) = MatrixB;

MatrixRGB(MatrixRGB<0) = 0;
end
