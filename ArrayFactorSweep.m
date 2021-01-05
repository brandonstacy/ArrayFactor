clear all;
clc;
warning off;

DCWeight = false;

startangle = -90;
endangle = 90;
anglestep = .1;

theta = startangle:anglestep:endangle;
freq = 2E9;
c0 = 299792458;
lambda = c0/freq;
k = 2*pi/lambda;
AFAz = 0;
AFEl = 0;

numAzChannels = 20; %Four minimum
numElChannels = 20; %Four minimum

ArrayElSpacing = lambda/2;
ArrayAzSpacing = lambda/2;
Azarray = (1:numAzChannels)*ArrayAzSpacing;
Elarray = (1:numElChannels)*ArrayElSpacing;

% n = 8;
% The first two rows are constant
pt(1, 1) = 1;
pt(2, 1 : 2) = [1 1]; 

% If only two rows are requested, then exit
if numAzChannels < 3 || numElChannels < 3
    return
end 

RectTaper = true;
CosTaper = false;
CosSqTaper = false;

AzCosTaper = -90:180/(numAzChannels-1):90;
ElCosTaper = -90:180/(numAzChannels-1):90;

for I = 1:numAzChannels
    if RectTaper
        AzDist(I) = 1;
    end
    if CosTaper
        AzDist(I) = cosd(AzCosTaper(I));
    end
    if CosSqTaper
        AzDist(I) = cosd(AzCosTaper(I))^2;
    end
end

for I = 1:numElChannels
    if RectTaper
        ElDist(I) = 1;
    end
    if CosTaper
        ElDist(I) = cosd(ElCosTaper(I));
    end
    if CosSqTaper
        ElDist(I) = cosd(ElCosTaper(I))^2;
    end
end

figure(10);
clf;
box on;
hold on;
xlim([2 numAzChannels-1]);
xlabel("Element");
ylabel("Normalized Power");
title("Antenna Azimuth Taper Distribution");
plot(10*log10(AzDist),"-o","LineWidth",1.5);

figure(11);
clf;
box on;
hold on;
xlim([2 numElChannels-1]);
xlabel("Element");
ylabel("Normalized Power");
title("Antenna Elevation Taper Distribution");
plot(10*log10(ElDist),"-o","LineWidth",1.5);

steerAngleAz = 0;
steerAngleEl = 0;
PlotAzAngle = 0;
PlotElAngle = 0;

SaveGif = false;
MakeGif = true;

if MakeGif
    filename = 'RaisedCosine.gif';
    h = figure(1);
    axis tight manual % this ensures that getframe() returns a consistent size
end

p = 0;
u = 0;
for steerAngleEl = -40:10:40
    for steerAngleAz = -40:10:40
        AFEl = 0;
        AFAz = 0;
        for n = 2:1:numAzChannels
            AFAz = AFAz+AzDist(n)*exp(1i*(n-1)*(k*(Azarray(n)-Azarray(n-1))*(sin(deg2rad(theta)) - sin(deg2rad(steerAngleAz)))));
        end
        for n = 2:1:numElChannels
            AFEl = AFEl+ElDist(n)*exp(1i*(n-1)*(k*(Elarray(n)-Elarray(n-1))*(sin(deg2rad(theta)) - sin(deg2rad(steerAngleEl)))));
        end
        AFEl = reshape(AFEl,[length(AFEl),1]);
        
        TotalArray = AFAz.*AFEl;
        TotalArray = 10*log10((abs(TotalArray)));
        
        if steerAngleAz == PlotAzAngle && p == 0
            p = 1;
            figure(2);
            hold on;
            clf;
            plot(theta,10*log10((abs(AFAz))),"Linewidth",1.5);
            xlim([-90 90]);
            ylim([-30 30]);
            box on;
            xlabel("Azimuth (deg)");
            ylabel("Gain (dB)");
            title("Beam Pattern Azimuth");
        end
        
        if steerAngleEl == PlotElAngle && u == 0
            u = 1;
            figure(3);
            hold on;
            clf;
            plot(theta,10*log10((abs(AFEl))),"Linewidth",1.5);
            xlim([-90 90]);
            ylim([-30 30]);
            xlabel("Elevation (deg)");
            ylabel("Gain (dB)");
            title("Beam Pattern Elevation");
            box on;
        end
        
        if steerAngleEl == PlotElAngle && steerAngleAz == PlotAzAngle
            figure(1);
            clf;
            imagesc(theta,theta,TotalArray);
            h = colorbar;
            colormap(jet);
            caxis([0 40]);
            xlim([-90 90])
            ylim([-90 90]);
            box on;
        end
        
        if MakeGif
            figure(1);
            clf;
            imagesc(theta,theta,TotalArray);
            h = colorbar;
            colormap(jet);
            caxis([-10 20])
            xlim([-90 90])
            ylim([-90 90]);
            xlabel("Elevation (\circ)");
            ylabel("Azimuth (\circ)");
            ylabel(h, 'Gain (dB)');
            %         set(get(h,'title'),'string','Gain (dB)');
            title("Raised Cosine Taper Gain (dB)");
            
            if SaveGif
                % Capture the plot as an image
                frame = getframe(h);
                im = frame2im(frame);
                [imind,cm] = rgb2ind(im,256);
                % Write to the GIF File
                if steerAngleEl == -45
                    imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
                else
                    imwrite(imind,cm,filename,'gif','WriteMode','append');
                end
            end
        end
    end
end