@import <AppKit/CPPanel.j>

/*

DCFileDropControllerDropDelegate protocol
- (void)fileDropUploadController:(DCFileDropController)theController setState:(BOOL)visible;

*/

DCFileDropableTargets = [ ];

@implementation DCFileDropController : CPObject {
	CPView view @accessors;

	DOMElement fileInput;
	id dropDelegate;
	CPURL *uploadURL;
	id uploadManager;
}

- (id)initWithView:(CPView)theView dropDelegate:(id)theDropDelegate uploadURL:(CPURL)theUploadURL uploadManager:(id)theUploadManager {
	self = [super init];

	view = theView;
	dropDelegate = theDropDelegate;
	uploadURL = theUploadURL;
	uploadManager = theUploadManager;

	[self setFileDropState:NO];

	var theClass = [self class],
	    dragEnterEventImplementation = class_getMethodImplementation(theClass, @selector(fileDraggingEntered:)),
	    dragEnterEventCallback = function (anEvent) {anEvent.dataTransfer.dropEffect = "copy"; dragEnterEventImplementation(self, nil, anEvent); },
        bodyBlockCallback = function(anEvent){if (![DCFileDropableTargets containsObject:anEvent.toElement]) {anEvent.dataTransfer.dropEffect = "none"; anEvent.preventDefault(); return NO;}else{return YES;}};

    // this prevents the little plus sign from showing up when you drag over the body.
    // Otherwise the user could be confused where they can drop the file and it would
    // cause the browser to redirect to the file they just dropped. 
    window.document.body.addEventListener("dragover", bodyBlockCallback, NO);

	theView._DOMElement.addEventListener("dragenter", dragEnterEventCallback, NO);

	fileInput = document.createElement("input");
	fileInput.type = "file";
	fileInput.id = "filesUpload";
	fileInput.style.position = "absolute";
	fileInput.style.top = "0px";
	fileInput.style.left = "0px";
	fileInput.style.backgroundColor = "#00FF00";
	fileInput.style.opacity = "0";
	fileInput.setAttribute("multiple",true);
	[self setFileElementVisible:NO];
    [DCFileDropableTargets addObject:fileInput];
	theView._DOMElement.appendChild(fileInput);

	var fileDroppedEventImplementation = class_getMethodImplementation(theClass, @selector(fileDropped:));
	var fileDroppedEventCallback = function (anEvent) { fileDroppedEventImplementation(self, nil, anEvent); };
	fileInput.addEventListener("change", fileDroppedEventCallback, NO);

	var dragExitEventImplementation = class_getMethodImplementation(theClass, @selector(fileDraggingExited:));
	var dragExitEventCallback = function (anEvent) { dragExitEventImplementation(self, nil, anEvent); };
	fileInput.addEventListener("dragleave", dragExitEventCallback, NO);

	return self;
}

- (void)setFileDropState:(BOOL)visible {
	if ([dropDelegate respondsToSelector:@selector(fileDropUploadController:setState:)]) {
		[dropDelegate fileDropUploadController:self setState:visible];
	}
}

- (void)setFileElementVisible:(BOOL)yesNo {
	if (yesNo) {
		fileInput.style.width = "100%";
		fileInput.style.height = "100%";
	} else {
		fileInput.style.width = "0%";
		fileInput.style.height = "0%";
	}
}

- (void)fileDraggingEntered:(id)sender {
	[self setFileDropState:YES];
	[self setFileElementVisible:YES];
}

- (void)fileDraggingExited:(id)sender {
	[self setFileDropState:NO];
	[self setFileElementVisible:NO];
}

- (void)fileDropped:(id)sender {
	[self setFileDropState:NO];
	[self setFileElementVisible:NO];

	var files = sender.target.files;
	for(var i = 0, len = files.length; i < len; i++) {
		if ([uploadManager respondsToSelector:@selector(fileUploadWithFile:uploadURL:)]) {
			[uploadManager fileUploadWithFile:files[i] uploadURL:uploadURL];
		}
	}
}

@end
