function [meanseats,SDseats,sigma,actual_Dseats,total_state_seats,num_matching,alpha]=gerry_fantasy_delegations(stateDvotes,Dvotes,symmet,number_of_simulated_delegations,outputfilename)
%
% paste into code that calls this code:
% [meanseats,SDseats,sigma,actual_Dseats,total_state_seats,num_matching,alpha]=gerry_fantasy_delegations(stateresults,nationalresults,1000000,outputfilename);
% or cut starting with line below, then paste into command window
% stateDvotes=stateresults;Dvotes=nationalresults;number_of_simulated_delegations=1000000';outputfilename='foo';
%
%
% gerry_fantasy_delegations.m - Stripped-down gerrymandering simulation. 
% Copyright Sam Wang under GNU License, 2016. 
% OK to copy, distribute, and modify, but retain this header
% 
% Princeton Election Consortium
% http://election.princeton.edu
% http://gerrymander.princeton.edu
%
% inputs:
%   stateDvotes
%
% outputs:
%   meanseats - average number of D seats in simulations
%   SDseats - standard deviation of D seats in simulations
%   sigma - binomial SD
%   actual_Dseats - number of actual D seats in delegation
%   total_state_seats - total number of seats in delegation
%   num_matching - number of simulations matching % vote criterion
%   alpha - one-tailed likelihood of actual outcome arising in simulations
%
% units are in fraction of two-party vote - multiply by 100 to get percentages
%
% alldistricts is the set of districts from which to build simulated delegations 
alldist=length(Dvotes); alldistricts=[1:alldist]; % all districts to be sampled
total_state_seats=length(stateDvotes); sdist=[1:total_state_seats];
% Dvotes=normrnd(0.5,0.15,size(alldistricts)); % create a symmetric distribution to sample from

% true delegation
s_dvote=sum(stateDvotes(sdist))/total_state_seats; % statewide average D vote share
actual_Dseats=sum(stateDvotes(sdist)>0.5); % number of actual D seats won

% simulate some delegations
clear p dseats

fantasydelDvotes=Dvotes(randi([1, alldist], total_state_seats, number_of_simulated_delegations)); % pick a random set of districts

if symmet
    flips=rand([total_state_seats number_of_simulated_delegations])>0.5;
    fantasydelDvotes(flips) = 1 - fantasydelDvotes(flips);
end

p=sum(fantasydelDvotes)/total_state_seats; % average two-party vote share in the simulated delegation
dseats=sum(fantasydelDvotes>0.5); % the simulated delegation has this many D seats

epsilon=0.001; % the larger this is, the closer sigma is to the expected. 0.001 means within 0.1%
% if epsilon=0.15 and SD of parent distribution is 0.15, sigma and std_sim are nearly the same
% if epsilon<<SD, seems to go toward 0.61 or so
% there is some kind of asymptotic behavior as the constraint is put on
%
closesims=find(abs(p-s_dvote)<epsilon); %find simulations within epsilon% in vote
num_matching=length(closesims);
meanseats=mean(dseats(closesims)); % mean simulated seats
meanseatshare=meanseats/total_state_seats; % mean simulated seats
sigma=sqrt(total_state_seats*meanseatshare*(1-meanseatshare)); % binomial error bar on s_sim
SDseats=std(dseats(closesims)); % SD of seat outcomes for this set

onetail=length(find(dseats(closesims)>=actual_Dseats));
othertail=length(find(dseats(closesims)<=actual_Dseats));
alpha=min(onetail,othertail)/num_matching;

% results = [meanseats SDseats sigma actual_Dseats total_state_seats num_matching alpha];

% plot all delegations
    Fig3 = figure(4);
    set(Fig3, 'Position', [600 300 600 500])
    title(['Analysis of Effects: ' num2str(number_of_simulated_delegations) ' Simulated delegations'])
    hold on
    plot(100*p,dseats,'.k')
    plot(100*s_dvote,actual_Dseats,'ok','MarkerSize',10,'MarkerFaceColor',[1 .3 .3],'LineWidth',1.5) % the actual outcome
    errorbar(100*s_dvote,meanseats,SDseats,'ok','MarkerSize',10,'MarkerFaceColor',[.3 1 .3],'LineWidth',1.5)
    grid on
    axis([25 75  -0.4 total_state_seats+0.4])
    xlabel('Statewide Democratic fraction of two-party vote (%)')
    ylabel('Democratic seats')
    set(gcf,'PaperPositionMode','auto')
    print([outputfilename '_Test3_hires.jpg'],'-djpeg','-r300')
    screen2jpeg([outputfilename '_Test3.jpg'])
