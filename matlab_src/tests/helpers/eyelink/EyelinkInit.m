function varargout = EyelinkInit(varargin) %#ok<STOUT,INUSD>
error('EyeLinkTest:InteractiveInit', ...
    'Setup must not call EyelinkInit, which can open the dummy-mode dialog.');
end
