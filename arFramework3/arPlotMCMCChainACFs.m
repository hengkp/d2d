% plot mcmc ACF

function arPlotMCMCChainACFs(jks, Nthinning, maxlag)

global ar

if(~exist('Nthinning','var'))
    Nthinning = 10;
end

if(~exist('maxlag','var'))
    maxlag = 50;
end

ps2 = ar.ps;
if(Nthinning>1)
    ps2 = ps2(mod(1:size(ps2,1),Nthinning)==1,:);
end
   
h = arRaiseFigure(pleGlobals, 'fighandel_multi', 'mcmc chains');
set(h, 'Color', [1 1 1]);

if(~exist('jks','var') || isempty(jks))
    jks = find(ar.qFit==1);
end


jks = jks(ar.qFit(jks)==1);

[nrows, ncols] = arNtoColsAndRows(length(jks));

count = 1;
for jk=jks
    g = subplot(nrows, ncols, count);
    
    acf = xcorr(ar.ps(:,jk)- mean(ar.ps(:,jk)), maxlag, 'coeff');
    plot(acf((maxlag+1):end), '*-', 'Color', [.5 .5 .5]);
    hold on
    
    if(Nthinning>1)
        acf = xcorr(ps2(:,jk)- mean(ps2(:,jk)), maxlag, 'coeff');
        plot(acf((maxlag+1):end), 'k*-');
    end
    
    title(sprintf('ACF for %s', strrep(ar.pLabel{jk}, '_', '\_')));
    xlim([0 maxlag]);
    ylim([min([-0.1 min(acf)]) 1.1]);
    
    plot(xlim, [0 0], 'k--')
    hold off
    
    if(Nthinning>1 && count==1)
        legend('no thinning', sprintf('1/%i thinning',Nthinning));
    end
    arSubplotStyle(g);
    
    count = count + 1;
end


