classdef sceneEye < hiddenHandle
% Create a sceneEye object
%
% Syntax:
%   myScene = sceneEye();
%
% Description:
%	 sceneEye contains the information needed to construct a new PBRT
%    file that we can then render to get a retinal image. 
%
%    sceneEye is analogous to the "scene" structure in ISETBIO (and
%    ISET), and it will support similar commands. Unlike the
%    ISET/ISETBIO "scene", as for new entities we created it as a
%    MATLAB class.
%
%    This code is starting out in service of the eyeModel. We may
%    extend to replace the scene structure (some day).
%
% Notes:
%    * TODO - Implement the check that BW describes below. Is there a way
%      to check inputs? For example, eyePos is not a dependent variable,
%      but is instead read in from the PBRT file. However, say the user
%      wants to change the value in their script so they write:
%           myScene = sceneEye('pbrtFile', xxx);
%           myScene.eyePos = [x y z]; 
%      Is there a way to ensure they put in a 3x1 vector for eyePos, other
%      than just rigourous error checking in the code?
%	 * [Note: BW - (Reference first TODO) Yes, I think so, using the
%	   myScene.set('eyePos', val) approach, or perhaps myScene.set.eyePos =
%	   val. In these cases the set operation can pass through an input
%	   parser that validates the input value (I think).]
%    * [Note: BW - I wonder if recipe should be a slot in here or whether
%      we should use myScene.render(recipe, varargin); The current way does
%      make sense, since this is actually a scene.]
%    * [Note: BW - maxDepth & nWaveBands are often empty, so let's perform
%      the checks below. However, I should find a more permanant solution
%      to cases like these. (See the note above). Maybe in
%      piGetRenderRecipe we should put in the default values if any of
%      these rendering options are missing (e.g. if Renderer is missing,
%      put in Renderer 'sampler'.)]
%    * TODO - Look (Constant property wave) up and fill it in.
%    * [Note: XXX - (from constructor) What happens if the recipe doesn't
%      include any of the following, or any of the subfields we call?]
%    * TODO - Determine a better way to infer the accommodation. Currently
%      we assume the naming conventions is "%s_%f.dat" This is not
%      foolproof, so maybe we can think of a more robust way to do this in
%      the future?
%    * [Note: TL - What does this hiddenHandle mean? I seem to need it to
%      avoid errors.]
%    * TODO - Fix example!
%
% See Also:
%    Dependencies: pbrt2ISET, ISETBIO
%

% History:
%    xx/xx/17  TL   ISETBIO Team, 2017
%    12/19/17  jnm  Formatting

% Examples:
%{
    % ETTBSkip.  Skip this example in ETTB, since it is known not to work.
    % When the example gets fixed, remove this line and the one above.
    %
    % [Note: JNM - Doesn't work for a number of reasons...]
    % sceneName = 'scene name';
	% fileName = 'fileName.pbrt';
    thisScene = sceneEye('name', sceneName, 'pbrtFile', fileName);
    thisScene.accommodation = double
    % ...
    oi = thisScene.render(varargin);
%}

properties (GetAccess=public, SetAccess=public)
    %NAME The name of the render
    name;

    %RESOLUTION resolution of render (pixels)
    %   Instead of rows/cols we use a general resolution variable. This
    %   is because the eye model can only take equal rows and columns
    %   and the rendered image is always square.
    resolution;

    %FOV Field of view of the render in degrees
    %   This value is calculated from the retina distance and the
    %   retina size. This is only a close approximation since the
    %   retina is very slightly curved.
    fov;

    %ACCOMMODATION Diopters of accommodation for 550 nm light
    %   We change the properties of the lens to match the desired
    %   accommodation. For example, if we set this to 5 diopters, 550
    %   nm rays from 0.2 meters will be in focus on the retina.
    accommodation;
    
    %ECCENTRICITY Horizontal and vertical angles on the retina 
    %   corresponding to the center of the rendered image. Positive angles
    %   are to the right/up (from the eye's point of view) and negative 
    %   angles are to the left/down. For example, an image with [0 0] 
    %   eccentricity is centered on the center of the retina. An image with 
    %   [30 0] eccentricity is centered 30 degrees to the right of the
    %   center of the retina.
    eccentricity;

    %PUPILDIAMETER Diameter of the pupil (mm)
    pupilDiameter;

    %RETINARADIUS The curvature of the retina in mm
    %   If one imagines the retina as asection of a sphere, this radius
    %   value determines the distance from the edge of the sphere to
    %   its center. We will not change this most of the time, but
    %   sometimes it is helpful to make the retina very flat in order
    %   to measure certain properties of the eye.
    retinaRadius;

    %retinaDistance Distance between the back lens and the retina
    %   We will not change this most of the time, but sometimes it is
    %   helpful to move the retina back and forth, like a camera
    %   sensor, to see things affects like chromatic aberration.
    retinaDistance;

    %NUMRAYS Number of rays to shoot per pixel.
    %   This determines the quality of the render and affects the time
    %   spent rendering. This should be a factor of 2. Low quality is
    %   typically 64 or256 rays, high quality is typically 2048 or 4096
    %   rays.
    numRays;

    %NUMBOUNCES Number of bounces before ray terminates
    %   This also determines how accurately light is modeled in the
    %   rendering. The amount needed is highly scene dependent.
    %   Typically set to 1 for simple, diffuse scenes. A high value
    %   would be 4-8 for scenes with lots of reflections, caustics, or
    %   glassy materials.
    numBounces;

    %NUMCABANDS Number of wavelength samples to take when modeling CA
    %   We shoot extra rays of different wavelengths in order to model
    %   chromatic aberration through the lens system. This determines
    %   the number of samples we take. For example, if we set this to 4
    %   we shoot rays at...
    numCABands;

    %EYEPOS Position of the eye within the scene in [x y z] format
    %   [x y z]
    eyePos;

    %EYETO Point where the eye is looking at
    %   [x y z], the difference between eyeTo and eyePos is the
    %   direction vector that the optical axis is aligned with.
    eyeTo;

    %EYEUP Up vector used when building the LookAt transform
    %   [x y z], this is typically [0 0 1] but it depends on how the
    %   eye is oriented. For example, if this was [0 0 -1] the eye
    %   would be "upside down." Some values are not valid, for example
    %   if the eye is looking down the z-axis (eyePos = [0 0 0], eyeTo
    %   = [0 0 1]) then the up vector cannot be [0 0 1].
    eyeUp;

    %DEBUGMODE Toggle debug mode.
    %   For debug mode we switch to a perspective camera with the same
    %   FOV as the eye. This can be potentially faster and easier to
    %   render than going through the eye.
    debugMode;
end

properties (Dependent)
    %WIDTH Width of imaged retina (mm)
    %   Depends on fov, retinaDistance, and rows/cols
    width;

    %HEIGHT Height of imaged retina (mm)
    %   Depends on fov, retinaDistance, and rows/cols
    height;

    %SAMPLESIZE Samples spacing, e.g. width/xRes and height/yRes.
    %   We assume square samples. This is not always accurate at large
    %   fov's.
    sampleSize;

end

properties(GetAccess=public, SetAccess=private)
    %LENSFILE Path to the .dat file that describes the lens system
    %   This file includes descriptions of the thickness, curvature, 
    %   and diameter of the various components in the eye.
    lensFile;

    % PBRTFILE Path to the original .pbrt file this scene is based on
    %   Depends on the pbrt file used to create the scene. Should not
    %   be changed.
    pbrtFile;

    %WORKINGDIR Directory to store temp files needed for rendering
    %   We make a copy of the scene into the working directory, and
    %   then output new PBRT files into this directory. We also save
    %   the raw rendered data (xxx.dat) in this folder.
    workingDir;

end

properties(Access=private)
    % The recipe stores pretty much everything else we read in from the
    % PBRT file that we don't want the user to access directly. This
    % includes things like the WorldBegin/WorldEnd block, the PixelFilter,
    % the Integrator, etc.

    %RECIPE Structure that holds all instructions needed to
    %   render the PBRT file. 
    recipe;

end

properties (Constant)
    %WAVE
    wave = []; % TODO Look it up and fill it in

end

methods
    % Constructor
    function obj = sceneEye(pbrtFile, varargin)
        % Initialize the sceneEye class
        %
        % Reads a PBRT file and fills out the information needed
        % for the sceneEye object. That object will be rendered
        % using the PBRT methods (docker image).

        p = inputParser;
        p.KeepUnmatched = true;
        % pbrtFile: Either a pbrt file or just a scene name
        p.addRequired('pbrtFile', @ischar);
        p.addParameter('name', 'scene-001', @ischar);
        p.addParameter('workingDirectory', '', @ischar);

        % Optional parameters used by scenes that consist of only a
        % planar surface (e.g. a slanted bar). We will move the plane to
        % the given distance (in mm) and, if applicable, attach the
        % provided texture. 
        p.addParameter('planeDistance', 1000, @isnumeric);
        p.addParameter('planeTexture', ...
            fullfile(piRootPath, 'data', 'imageTextures', ...
            'squareResolutionChart.exr'), @ischar);
        p.addParameter('planeSize', [1000 1000], @isnumeric);
        p.parse(pbrtFile, varargin{:});

        % Read in PBRT file
        [~, name, ext] = fileparts(pbrtFile);

        if(isempty(ext))
            % The user has given us a scene name and not a full pbrt
            % file. Let's find the right file.
            switch name
                case('numbersAtDepth')
                    scenePath = fullfile(isetbioDataPath, 'pbrtscenes', ...
                        'NumbersAtDepth', 'numbersAtDepth.pbrt');
                case('slantedBar')
                    scenePath = fullfile(isetbioDataPath, 'pbrtscenes', ...
                        'SlantedBar', 'slantedBar.pbrt');
                case('chessSet')
                    scenePath = fullfile(isetbioDataPath, 'pbrtscenes', ...
                        'ChessSet', 'chessSet.pbrt');
                case('texturedPlane')
                    % Textured plane scene is located in pbrt2ISET. 
                    scenePath = fullfile(piRootPath, 'data', ...
                        'texturedPlane', 'texturedPlane.pbrt');
                otherwise
                    error('Did not recognize scene type.');
            end
        else
            scenePath = pbrtFile;
        end

        % Setup working folder
        if(isempty(p.Results.workingDirectory))
            % Determine scene folder name from scene path
            [path, ~, ~] = fileparts(scenePath);
            [~, sceneFolder] = fileparts(path);
            obj.workingDir = fullfile(...
                isetbioRootPath, 'local', sceneFolder);
        else
            obj.workingDir = p.Results.workingDirectory;
        end

        obj.pbrtFile = createWorkingFolder(...
            scenePath, 'workingDir', obj.workingDir);

        % Parse PBRT file
        recipe = piRead(obj.pbrtFile);
        % recipe.outputFile = obj.pbrtFile;
        recipe.inputFile = scenePath;

        % Apply optional parameters to unique scenes
        if(strcmp(name, 'slantedBar'))
            recipe = piMoveObject(recipe, '1_WhiteCube', ...
                'Translate', [0 p.Results.planeDistance 0]);
            recipe = piMoveObject(recipe, '2_BlackCube', ...
                'Translate', [0 p.Results.planeDistance 0]);
        elseif(strcmp(name, 'texturedPlane'))
            % Scale and translate
            planeSize = p.Results.planeSize;
            scaling = [planeSize(1) 1000 planeSize(2)] ./ [1000 1000 1000]; 
            recipe = piMoveObject(recipe, 'Plane', 'Scale', scaling); 
            recipe = piMoveObject(recipe, 'Plane', ...
                'Translate', [0 p.Results.planeDistance 0]); 
            % Texture
            [pathTex, nameTex, extTex] = fileparts(p.Results.planeTexture);
            copyfile(p.Results.planeTexture, obj.workingDir);
            if(isempty(pathTex))
                error('Image texture must be an absolute path.');
            end
            recipe = piWorldFindAndReplace(recipe, 'dummyTexture.exr', ...
                strcat(nameTex, extTex));
        end

        % [Note: XXX - What happens if the recipe doesn't include any of
        % the following, or any of the subfields we call?]

        % Check to make sure this PBRT file has a realistic eye.
        if(~strcmp(recipe.camera.subtype, 'realisticEye'))
            % error(['This PBRT file does not include a '
            %    '"realistic eye" camera class.'])
            recipe.camera = piCameraCreate('realisticEye');
        end

        % Set properties
        obj.name = p.Results.name;
        obj.resolution = recipe.film.xresolution.value;
        obj.retinaDistance = recipe.camera.retinaDistance.value;
        obj.pupilDiameter = recipe.camera.pupilDiameter.value;

        obj.retinaDistance = recipe.camera.retinaDistance.value;
        obj.retinaRadius = recipe.camera.retinaRadius.value;

        retinaSemiDiam = recipe.camera.retinaSemiDiam.value;
        obj.fov = 2 * atand(retinaSemiDiam / obj.retinaDistance);

        % There's no variable for accommodation but we can infer it
        % from the name of the lens. We assume the naming conventions
        % is "%s_%f.dat" This is not foolproof, so maybe we can think
        % of a more robust way to do this in the future?
        obj.lensFile = recipe.camera.specfile.value;
        if(strcmp(obj.lensFile, ''))
            obj.accommodation = [];
        else
            % Use regular expressions to find any floats within the string
            value = regexp(obj.lensFile, '(\d+, )*\d+(\.\d*)?', 'match');
            obj.accommodation = str2double(value{1});
        end

        obj.numRays = recipe.sampler.pixelsamples.value;

        % These two are often empty, so let's do checks here. However, 
        % I should find a more permanant solution to cases like these.
        % (See note above).
        % Maybe in piGetRenderRecipe we should put in the default
        % values if any of these rendering options are missing
        % (e.g. if Renderer is missing, put in Renderer 'sampler'.)
        if(isfield(recipe.integrator, 'maxdepth'))
            obj.numBounces = recipe.integrator.maxdepth.value;
        else
            obj.numBounces = 1;
        end
        if(isfield(recipe.renderer, 'nWaveBands'))
            obj.numCABands = recipe.renderer.nWaveBands.value;
        else
            obj.numCABands = 0;
        end

        if(~isempty(recipe.lookAt))
            obj.eyePos = recipe.lookAt.from;
            obj.eyeTo = recipe.lookAt.to;
            obj.eyeUp = recipe.lookAt.up;
        end

        obj.recipe = recipe;
        obj.debugMode = false;
        
        obj.eccentricity = [0 0];
    end

    %% Get methods for dependent variables
    function val = get.width(obj)
        % Rendered image is alway square.
        val = 2 * tand(obj.fov / 2) * obj.retinaDistance;
    end

    function val = get.height(obj)
        % Rendered image is alway square.
        val = 2 * tand(obj.fov / 2) * obj.retinaDistance;
    end

    function val = get.sampleSize(obj)
        val = (2 * tand(obj.fov / 2) * obj.retinaDistance) ...
            / obj.resolution;
    end

    %% Set methods for dependent variables
    function set.width(obj, val)
        obj.fov = 2 * atand((val / 2) / obj.retinaDistance);
    end

    function set.height(obj, val)
        obj.fov = 2 * atand((val / 2) / obj.retinaDistance);
    end

    function set.sampleSize(obj, val)
        obj.fov = 2 * atand((val * obj.resolution / 2) ...
            / obj.retinaDistance);
    end

end

methods (Access=public)
    [oi, terminalOutput, outputFile] = render(obj, varargin);
end

end
