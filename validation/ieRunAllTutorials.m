function iePublishAllTutorials

    % ------- script customization - adapt to your environment/project -----
    
    % user/project specific preferences
    p = struct(...
        'rootDirectory',            fileparts(which(mfilename())), ...                         % the rootDirectory
        'ghPcloagesCloneDir',          getpref('isetbio', 'clonedGhPagesLocation'), ... % local directory where the project's gh-pages branch is cloned
        'wikiCloneDir',             getpref('isetbio', 'clonedWikiLocation'), ...    % local directory where the project's wiki is cloned
        'tutorialsSourceDir',       fullfile(isetbioRootPath, 'tutorials'), ...                % local directory where tutorial scripts are located
        'tutorialDocsURL',          'http://isetbio.github.io/isetbio/tutorialdocs', ...       % URL where tutorial docs should go
        'headerText',               '***\n_This file is autogenerated by the ''publishAllTutorials'' script, located in the $isetbioRoot/validation directory. Do not edit manually, as all changes will be overwritten during the next run._\n***',...
        'verbosity',                1 ...
    );

    % list of scripts to be skipped from automatic publishing
    scriptsToSkip = {...
        't_coneMosaicLowPassResponses' ...  % this works stand-alone but freezes when run from this script
        't_coneMosaicDemosaicResponses' ... % this works stand-alone but freezes when run from this script
        't_osCurrentsVsLuminanceLevel' ...  % takes too long to run.
        't_rgcConeHex' ...                  % Calls ieStimulusBar, which calls the compute method with an 'append' flag, that is not allowed anymore
        't_linearFilters' ...               % Runs stand-alone but throws an error when run from here.
        't_rgcGabor' ...                    % Broken because it relies on stale cached data, and it isn't clear what should be in the cache.
        };
    % ----------------------- end of script customization -----------------
    
    UnitTest.runProjectTutorials(p, scriptsToSkip, 'All');
end