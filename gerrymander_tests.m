function results=gerrymander_tests(year,states,yearbaseline,statebaseline,imputedzero,symm,state_label,outputfilename)

% make double JPEGs, one high resolution

% parameters
%   year - Election year to be analyzed. If in [1898:2:2100], 'states' is state number
%   states - State code. If year==0, then put an election data array here!
%   yearbaseline - Election year to be resampled for simulation-based test;
%       if it's zero, then 'statebaseline' should contain an array of
%       election data
%   statebaseline - States to be resampled. If yearbaseline==0, put election data here!
%   imputedzero - User value for what to do about uncontested races
%   symm - User option to use population symmetry as the ideal baseline
%   state_label - A string to allow user to define state/race (i.e.
%      'Arizona State Senate')
%   outputfilename - The prefix of the output file names to be written

% dummy parameters - comment out this line for actual use
% example: gerrymander_tests(2012,38,2012,0,0.25,0,'Pennsylvania','foo');
% year=2012;states=38;yearbaseline=2012;statebaseline=0;imputedzero=0.25;symm=0;state_label='Pennsylvania';outputfilename='foo';
% example: gerrymander_tests(2014,20,2014,0,0.25,0,'Maryland','foo');
% year=2012;states=20;yearbaseline=2012;statebaseline=0;imputedzero=0.25;symm=0;state_label='Maryland';outputfilename='foo';

switch 1
    case year==0
        statedata=states; % use the variable "states" as the voting results data
    case ismember(year,[1898:2:2100])
        % states can represent one or multiple states
        statedata=gerrymander_readresults(year,states);
        statename=gerrymander_statename(states); % Two-letter name of state
    otherwise % just do Pennsylvania 2012
        statedata=gerrymander_readresults(2012,38);
        statename=gerrymander_statename(38);
        warning('Parameters didn''t parse - defaulting to Pennsylvania 2012');
end

switch 1
    case yearbaseline==0
        nationaldata=statebaseline; % use the variable "statebaseline" as the voting results data
    case ismember(yearbaseline,[1898:2:2014])
        if statebaseline(1)<1
            nationaldata=gerrymander_readresults(yearbaseline,1:50);
        else
            nationaldata=gerrymander_readresults(yearbaseline,statebaseline);
        end
    otherwise % just do Pennsylvania 2012
        nationaldata=gerrymander_readresults(2012,1:50);
        warning('Parameters didn''t parse - defaulting national data to 2012');
end

%
% calculate basic parameters from the data
%
stateraw=statedata(:,3);
nationalraw=nationaldata(:,3);

N_delegates=length(stateraw); 
D_districts=find(stateraw>=0.5);
R_districts=find(stateraw<0.5);
N_D=length(D_districts); 
N_R=N_delegates-N_D;

imputedzero=min(imputedzero,1); imputedzero=max(imputedzero,0);
imputedfloor=min(imputedzero,1-imputedzero);

stateresults=stateraw;
stateresults(find(stateresults==0))=imputedfloor;
stateresults(find(stateresults==1))=1-imputedfloor;
nationalresults=nationalraw;
nationalresults(find(nationalresults==0))=imputedfloor;
nationalresults(find(nationalresults==1))=1-imputedfloor;

D_mean_raw=mean(stateraw);
R_mean_raw=1-D_mean_raw;
D_mean=mean(stateresults);
R_mean=1-D_mean;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Start calculating and writing output %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid=fopen(strcat(outputfilename,'.html'),'w');

site='http://gerrymander.princeton.edu';
msg='Gerrymandering analyzer from Prof. Sam Wang, Princeton University';
fprintf(fid,'<a href = "%s">%s</a><br>\n<br>\n',site,msg)
msg='Reference: 68 Stan. L. Rev. XX, 2016.';
fprintf('fid,%s<br>\n<br>\n',msg)

state_name=gerrymander_statename(states); % will give two-letter abbreviation of state
formatSpec='The %s state delegation of %d had %d seats, %d Democratic/other and %d Republican.<br>\n';
fprintf(fid,formatSpec,state_name,year,N_delegates,N_D,N_R);

fprintf(fid,'The average Democratic share of the two-party total vote was %2.1f%% (raw)',D_mean_raw*100);
if ~(D_mean_raw==D_mean)
    fprintf(fid,', %2.1f%% with imputation of uncontested races',D_mean*100);
end
fprintf(fid,'.<br>\n<br>\n');

fprintf(fid,'<b>Analysis of Intents</b><br>\n<br>\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Test for lopsided win margins %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(fid,'If a political party wishes to create for itself an advantage, it will pack its opponents to win overwhelmingly in a small number of districts, while distributing its own votes more thinly. ');
fprintf(fid,'To test for a lopsided advantage, one can compare each party''s winning margins and see if they are systematically different. ');
fprintf(fid,'This is done using the <a href="http://vassarstats.net/textbook/ch11pt1.html">two-sample t-test</a>. ');
fprintf(fid,'In this test, the party with the <i>smaller</i> set of winning margins has the advantage.<br>\n<br>\n');

fprintf(fid,'<b>First Test of Intents: Probing for lopsided win margins (the two-sample t-test):</b> ');
if and(N_D>=2,N_R>=2)
    [h1,p1,CI1,stats1]=ttest2(stateresults(D_districts), 1-stateresults(R_districts), 'Vartype', 'unequal');
    switch 1
        case p1>0.05
            fprintf(fid,'The difference between the two parties'' win margins does not meet established standards for statistical significance. ');
            fprintf(fid,'The probability that this difference or larger could have arisen by partisan-unbiased mechanisms is %1.2f.',p1);
        case p1<=0.05
            fprintf(fid,'The difference between the two parties'' win margins meets established standards for statistical significance. ');
            if p1>=0.01
                fprintf(fid,'The probability that this difference in win margins (or larger) would have arisen by partisan-unbiased mechanisms alone is %1.2f. ',p1);
            else
                if p1>=0.001
                    fprintf(fid,'The probability that this difference in win margins (or larger) would have arisen by partisan-unbiased mechanisms alone is %1.3f. ',p1);
                else
                    fprintf(fid,'The probability that this difference in win margins (or larger) would have arisen by partisan-unbiased mechanisms alone is less than 0.001. ');
                end
            end
    end
    fprintf(fid,'<br>\n<br>\n');
    
% JPEG: make and save a scatter plot with outputfilename_Test1.jpg and outputfilename_Test1_hires.jpg 
    close all
    Fig1 = figure(1);
    set(Fig1, 'Position', [100 100 600 150])
    title('Analysis of Intents: Lopsided wins by one side')
    hold on

    plot(100*stateraw(D_districts),1,'ok','MarkerFaceColor',[.65 .65 1],'LineWidth',1)
    mean_Dshare=mean(100*stateraw(D_districts));
    plot([mean_Dshare mean_Dshare],[0.6 1.4],'-k')
    plot(100-100*stateraw(R_districts),2,'ok','MarkerFaceColor',[1 .3 .3],'LineWidth',1)
    mean_Rshare=100-mean(100*stateraw(R_districts));
    plot([mean_Rshare mean_Rshare],[1.6 2.4],'-k')

    axis([48 102 .5 2.5])
    xlabel('Winning vote percentage')
    set(gca,'XTick',[50 60 70 80 90 100]);
    set(gca,'YTick',[1 2]);
    set(gca,'YTickLabel',{'Democratic','Republican'});    
    set(gcf,'PaperPositionMode','auto')
	print([outputfilename '_Test1_hires.jpg'],'-djpeg','-r300') % uses paper options https://www.mathworks.com/matlabcentral/answers/102382-how-do-i-specify-the-output-sizes-of-jpeg-png-and-tiff-images-when-using-the-print-function-in-mat
    screen2jpeg([outputfilename '_Test1.jpg'])

    fprintf(fid,'<IMG SRC="%s_Test1.jpg" border="0" alt="Logo"><br>\n',outputfilename);
else
    fprintf(fid,'Can''t compare win margins. For this test, both parties must have at least two seats.<br>\n<br>\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Test for consistent advantage %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(fid,'<b>Second Test of Intents: Probing for consistent advantages for one party (mean-median difference and/or chi-square test):</b> ');
fprintf(fid,'The choice of test depends on whether the parties are closely matched (mean-median difference) or one party is dominant (chi-square test of variance).<br>\n<br>\n');

partisan_balance=abs(mean(stateresults)-0.5);

if partisan_balance<0.07
    fprintf(fid,'When the parties are closely matched in overall strength, a partisan advantage will be evident in the form of a difference between the mean (a.k.a. average) vote share and the median vote share, calculated across all districts. Partisan gerrymandering arises not from single districts, but from patterns of outcomes. Thus a single lopsided district may not be an offense - indeed, single-district gerrymandering is permitted by Supreme Court precedent. Rather, it is combinations of outcomes that confer undue advantage to one party or the other.<br>\n<br>\n');
    % mean minus median test
    mean_median_diff=mean(stateresults)-median(stateresults);
    SK_mmdiff=mean_median_diff/std(stateresults)*sqrt(length(stateresults)/0.5708); % the 0.5708 comes from p. 352 of Cabilio and Masaro 1996
    pvalue_mmdiff=min(normcdf(SK_mmdiff),1-normcdf(SK_mmdiff)); % One-tailed p-value, usually appropriate since most testers have a direction in mind

    if mean_median_diff<0
        fprintf(fid,'The mean-median difference is %2.1f%% in a direction of advantage to the Democratic Party. ',abs(mean_median_diff)*100);
    else
        if mean_median_diff>0
            fprintf(fid,'The mean-median difference is %2.1f%% in a direction of advantage to the Republican Party. ',abs(mean_median_diff)*100);
        else
            fprintf(fid,'The mean and median are identical, suggesting no identifiable advantage to either major party. This can occur in situations where all races are uncontested.');
        end
    end
    
    fprintf(fid,'The mean-median difference would reach this value in %2.1f%% of situations by a partisan-unbiased process. ',pvalue_mmdiff*100);
    if pvalue_mmdiff<0.01
        fprintf(fid,'This difference is statistically significant (p<0.01), and is extremely unlikely to have arisen by chance. ');
    else
        if pvalue_mmdiff<0.05
            fprintf(fid,'This difference is statistically significant (p<0.05), and is unlikely to have arisen by chance. ');
        else
            fprintf(fid,'This difference is not statistically significant (p>0.05). ');
        end
    end
    fprintf(fid,'<br>\n<br>\n');    
    
% JPEG: Show data in a single plot, mean and median indicated, save as outputfilename_Test2a.jpg
    Fig2a = figure(2);
    set(Fig2a, 'Position', [100 400 600 150])
    title('Analysis of Intents: Mean-median difference in vote share')
    hold on
    
    plot(100*stateraw(D_districts),1,'ok','MarkerFaceColor',[.65 .65 1],'LineWidth',1)
    plot(100*stateraw(R_districts),1,'ok','MarkerFaceColor',[1 .3 .3],'LineWidth',1)
    mean_Dshare=mean(100*stateraw(D_districts));
    plot([mean(stateresults)*100 mean(stateresults)*100],[0.6 1.4],'-k')
    plot([median(stateresults)*100 median(stateresults)*100],[0.8 1.2],'-r')
    axis([-2 102 0.6 1.4])
    % add labels for average and median
    % would be cool to show zone of chance
    
    xlabel('Democratic Party vote share (%)')
    set(gca,'XTick',[0 10 20 30 40 50 60 70 80 90 100]);
    set(gca,'YTick',[1]);
    set(gca,'YTickLabel',gerrymander_statename(states));    
    set(gcf,'PaperPositionMode','auto')
    print([outputfilename '_Test2a_hires.jpg'],'-djpeg','-r300') % uses paper options https://www.mathworks.com/matlabcentral/answers/102382-how-do-i-specify-the-output-sizes-of-jpeg-png-and-tiff-images-when-using-the-print-function-in-mat
    screen2jpeg([outputfilename '_Test2a.jpg'])
    
    fprintf(fid,'<IMG SRC="%s_Test2a.jpg" border="0" alt="Logo"><br>\n<br>\n',outputfilename);    
end

if partisan_balance>0.05
    fprintf(fid,'When one party is dominant statewide, it gains an overall advantage by spreading its strength as uniformly as possible across districts. The statistical test to detect an abnormally uniform pattern is the chi-square test, in which the vote share of the majority party-controlled seats are compared with nationwide patterns.<br>\n<br>\n');
    % chi square test on majority of delegation
    if length(D_districts)>length(R_districts)
        varcompare=var(stateresults(find(stateresults)>0.5));
        [h2b,p2b,ci2b,stats2b] = vartest(stateresults(D_districts),varcompare,'Tail','left');
        fprintf(fid,'The standard deviation of the Democratic majority''s winning vote share is %2.1f%%. ',std(stateresults(D_districts))*100);
        fprintf(fid,'At a national level, the standard deviation is %2.1f%%. ',sqrt(varcompare)*100);
    else
        varcompare=var(stateresults(find(stateresults)<0.5));
        [h2b,p2b,ci2b,stats2b] = vartest(stateresults(R_districts),varcompare,'Tail','left');
        fprintf(fid,'The standard deviation of the Republican majority''s winning vote share is %2.1f%%. ',std(stateresults(R_districts))*100);
        fprintf(fid,'At a national level, the standard deviation is %2.1f%%. ',sqrt(varcompare)*100);
    end 
    if p2b<0.01
        fprintf(fid,'This difference is statistically significant (p<0.01), and is extremely unlikely to have arisen by chance. ');
    else
        if p2b<0.05
            fprintf(fid,'This difference is statistically significant (p<0.05), and is unlikely to have arisen by chance. ');
        else
            fprintf(fid,'This difference is not statistically significant (p>0.05). ');
        end
    end
    
% JPEG: show barplot of all districts
% inset message, SD of majority district vote share, compare with national SD
    Fig2b = figure(3);
    set(Fig2b, 'Position', [600 100 600 300])
    title('Analysis of Intents: Chi-square test for unusually uniform outcomes')
    hold on
% plot zone of chance for majority?
	plot([0 length(D_districts)+length(R_districts)+0.5],[50 50],'-k');
    bar([1:length(D_districts)],100*stateraw(D_districts),'b')
	bar([length(D_districts)+1:length(D_districts)+length(R_districts)],100*stateraw(R_districts),'r')
    axis([0 length(D_districts)+length(R_districts)+0.5 0 100]);
    xlabel('Districts (sorted by vote share)')
    ylabel('Democratic vote share (%)')
    set(gca,'XTick',[]);
    set(gca,'YTick',[0 10 20 30 40 50 60 70 80 90 100]);

    set(gcf,'PaperPositionMode','auto')
    print([outputfilename '_Test2b_hires.jpg'],'-djpeg','-r300')
    screen2jpeg([outputfilename '_Test2b.jpg'])

    fprintf(fid,'<IMG SRC="%s_Test2b.jpg" border="0" alt="Logo"><br>\n<br>\n',outputfilename);    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Analysis of Effects: excess seats %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[meanseats SDseats sigma actual_Dseats total_state_seats num_matching p3]=gerry_fantasy_delegations(stateresults,nationalresults,symm,1000000,outputfilename);
fprintf(fid,'<b>Test of effects: How many extra seats did either party gain relative to party-neutral sampling? (fantasy delegations)</b>: ');
fprintf(fid,'It is possible to estimate how the state''s delegation would be composed if votes were distributed according to natural variations in districting. ');
fprintf(fid,'This is done by drawing districts at random from a large national sample, and then examining combinations whose vote totals are similar to the actual outcome. ');
if symm==0
    fprintf(fid,'In the following simulations, the "fantasy delegations" give a sense of what would happen on average, based on national standards for districting. The sampled districts include urbanized areas, and therefore the simulations include the Republican advantage arising from population clustering.');
else
    fprintf(fid,'In the following simulations, the "fantasy delegations" were drawn from a partisan-symmetric distribution. Consequently, these simulations ignore population clustering and show what would occur in a fully partisan-symmetric situation.');
end
fprintf(fid,'<br>\n<br>\n');

fprintf(fid,'<IMG SRC="%s_Test3.jpg" border="0" alt="Logo"><br>\n',outputfilename);

fprintf(fid,'In this election, the average Democratic vote share across all districts was %2.1f%%, and Democrats won %i seats. ',mean(stateresults)*100, actual_Dseats);
fprintf(fid,'%i fantasy delegations with the same vote share had an average of %.1f Democratic seats (green symbol), with a standard deviation of %.1f seats (see error bar). ',num_matching,meanseats,SDseats);
fprintf(fid,'The actual outcome (red symbol) was therefore advantageous to');
switch 1
	case meanseats-actual_Dseats<0
        fprintf(fid,' Democrats. ');
    case meanseats-actual_Dseats>0
        fprintf(fid,' Republicans. ');
end

switch 1
    case p3>0.05
        fprintf(fid,'However, this advantage was not statistically significant. ');
    case p3<=0.05
        fprintf(fid,'This advantage meets established standards for statistical significance, and ');
        if p3>=0.01
            fprintf(fid,'the probability that it would have arisen by partisan-unbiased mechanisms alone is %1.2f. ',p3);
        else
            if p3>=0.001
                fprintf(fid,'the probability that it would have arisen by partisan-unbiased mechanisms alone is %1.3f. ',p3);
            else
                fprintf(fid,'the probability that it would have arisen by partisan-unbiased mechanisms alone is less than 0.001. ');
            end
        end
end
fprintf(fid,'<br>\n<br>\n');    

fprintf(fid,'The above calculations are based on Samuel S.-H. Wang, "Three Tests for Practical Evaluation of Partisan Gerrymandering," 68 Stan. L. Rev. XX (2016). For further information, contact sswang@princeton.edu.');
fprintf(fid,'<br>\n<br>\n');    

fclose(fid)
results=1;
end
