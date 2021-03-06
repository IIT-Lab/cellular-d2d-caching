clear all;
clc;

CatalogSize = 100;
% NumRequests = 10000000;
CacheSizeSamples = 1:5:21;

ZipfExponent = 0.8;
weights = 1:CatalogSize;
weights = weights.^(-ZipfExponent);
% weights = ones(1,CatalogSize);
weights = weights./sum(weights);

HitRateVec = zeros(1,length(CacheSizeSamples));
HitRateVecAcc = zeros(1,length(CacheSizeSamples));
TcVec = zeros(1:length(CacheSizeSamples));
% a=load('requestorder.mat');
% b=load('timeline.mat');
% ContentRequests  =a.req_order;
% TimeOfRequests = b.sort_time_line;

NumRequests = 100000;
NumRuns = 1;

for inds = 1:NumRuns
    fprintf('\nRun = %d\n',inds);
    %
    TcTh  =0;
    i = 1;
    for CacheSize = CacheSizeSamples
        tic
        TimeOfRequests = cumsum(exprnd( ones(1,NumRequests)));
        ContentRequests = randsample(CatalogSize,NumRequests,'true',weights);
        %                 Find Tc;

        PinVecTh = 1-exp(-weights*TcTh);
        
        while sum(PinVecTh) < CacheSize
            TcTh = TcTh + 0.01;
            PinVecTh = 1-exp(-weights*TcTh);
        end
%         cache = LFRU_Cache(CacheSize,CatalogSize,TcTh);
        TcVec(i) = TcTh;
        
        cache = LRU_Cache(CacheSize,CatalogSize);
        
        %         printCache(cache);
        HitCountVec = zeros(1,CatalogSize);
        RequestCountVec = zeros(1,CatalogSize);
        
        fprintf('Started simulation of isolated cache. C = %d, M = %d: ',CacheSize, CatalogSize);
        for index = 1:NumRequests
            
            CID = ContentRequests(index);
            ToR = TimeOfRequests(index);
            %         fprintf('\nemulate: CID = %d, ToR = %f',CID,ToR);
            RequestCountVec(CID) = RequestCountVec(CID) + 1;
            
            hit =  emulate(cache, CID ,ToR);
            
            ToR;
            if (hit == 1)
                HitCountVec(CID) = HitCountVec(CID) + 1;
            end
            
            if ( rem(index, round(NumRequests/10) ) == 0)
                fprintf('...%d',10*round(index/round(NumRequests/10)));
            end
        end
        %RequestCountVec(10)
        fprintf('\n');
        HitRateVec(i) = sum(HitCountVec)/sum(RequestCountVec);

        tsa = getTimerStructArray(cache);
        PinVec = zeros(1,CatalogSize);
        PhVec =  HitCountVec./RequestCountVec;
        
        meanTcVec = zeros(1,CatalogSize);
        stdTcVec = zeros(1,CatalogSize);
        
        for index = 1:CatalogSize
            [Ton, Toff, Tc] = derive_ON_OFF_Tc( tsa(index).time );
            PinVec(index) = min(sum(Ton)/sum(Ton+Toff),1);
            TcArray(index).tc = Tc; 
            meanTcVec(index) = mean(Tc);
            stdTcVec(index) = std(Tc);
        end
        fprintf('CacheSize = %d,TcTh = %f, meanTC = %f, std(Tc) = %f\n',CacheSize,TcTh,mean(meanTcVec), std(meanTcVec));
        i = i +1;
        toc
    end
    
    plot(CacheSizeSamples,HitRateVec,'+r'); hold on;
    HitRateVecAcc = HitRateVec + HitRateVecAcc;
end
plot(CacheSizeSamples, HitRateVecAcc/NumRuns,'r');

title('Black LRU Red LFU  Blue mod-TTL green mod-TTL + LRU  gree-dashed  LR + LRU red-solid MLFU red-dashed LFU');

%%

% Black LRU
% Red-solid LFU
% Red-dashed MLFU
% Blue TTL-LFU
% green TTL-LFU + LRU
% green-dashed  TTL-LR + LRU
% Blue-solid - TTL-LR + LRU
%%
TcTh = [1.020000  6.620000 13.130000  20.590000  29.070000  ];
meanTcVec = [ 0.997181  6.526040  13.023149 20.397954 28.784865 ];
stdTcVec = [ 0.041540  0.111979  0.167404 0.292257  0.491289];

plot(CacheSizeSamples,TcTh,'+'); hold on;
plot(CacheSizeSamples,meanTcVec,'r')
legend('Mean Tc Simulation','Tc Theoretical');
xlabel('C');
ylabel('Tc');
title('M = 100, Zipf = 0.8');
grid on;
%%
maxHitRate = zeros(1,CatalogSize);

for index = 1:CatalogSize
   maxHitRate(index) = sum(weights(1:index))/sum(weights);
end

hold on;
plot(1:CatalogSize,maxHitRate,'g');
%%
for index = 1:CatalogSize
    plot(abs(tsa(index).time), sign(tsa(index).time));
    pause(1)
end

%%
% 
% LFU_HitRate_5_5_95 = [0.2329    0.3380    0.4612    0.4682    0.4912    0.5972    0.6346    0.6482    0.6614    0.7397    0.7760    0.8049    0.8273    0.8661    0.8963    0.9122    0.9423    0.9616    0.9809];
% 
% LRU_HitRate_5_5_95 = [0.1503    0.2631    0.3535    0.4306    0.4958    0.5524    0.5997    0.6453    0.6856    0.7222    0.7602    0.7939    0.8269    0.8557    0.8824    0.9098    0.9328    0.9579    0.9802];
% 
% % save('isolated_cache_c1.5.100_m100.mat');
% %% Theoretical Calculations
% clear all;
% CatalogSize = 100;
% ZipfExponent = 2;
% weights = 1:CatalogSize;
% weights = weights.^(-ZipfExponent);
% % weights = ones(1,CatalogSize);
% weights = weights./sum(weights);
% 
% LHS = zeros(1,length(weights)-1);
% index = 1;
% TcSamples = 1:10:10000;
% for Tc = TcSamples
%     PinVec = 1-exp(-weights*Tc);
%     LHS(index) = sum(PinVec);
%     index = index + 1;
% end
% 
% plot(LHS,TcSamples)
% title('M=100,Zipf = 2,Tc = 1:10:10000');
% xlabel('Tc');
% ylabel('LHS');
% %%
tsa = getTimerStructArray(cache);

PinVec = zeros(1,CatalogSize);
PhVec =  HitCountVec./RequestCountVec;

meanTcVec = zeros(1,CatalogSize);
stdTcVec = zeros(1,CatalogSize);

for index = 1:CatalogSize
    [Ton, Toff, Tc] = derive_ON_OFF_Tc( tsa(index).time );
    PinVec(index) = min(sum(Ton)/sum(Ton+Toff),1);
    meanTcVec(index) = mean(Tc);
    stdTcVec(index) = std(Tc);
end

%%
plot(PinVec);hold on;
plot(PinVec,'r');

plot(PhVec,'k');
plot(PhVecTh,'m');



%%
for ind = 1:CatalogSize
    [ton, toff, tc] = derive_ON_OFF_Tc( tsa(ind).time );
    hist(tc);
    axis([0 200 0 100]);
    pause(1);
end


%%











