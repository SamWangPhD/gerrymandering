function outputset=district_results(year,states)

housedata=load('House_1898_2014_voteshares_notext.csv');
% columns are: Year	State	District	D_voteshare	Incumbent	Winner

% note that gerrymander_statename(rownum,2) will give rownum's state as a two-letter
% postal abbreviation

districts=intersect(find(housedata(:,1)==year),find(ismember(housedata(:,2),states)));
outputset=housedata(districts,2:6); % note that size(outputset,1) will return how many districts were found

end