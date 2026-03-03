import type { ViewProps } from 'react-native';
import type { WithDefault } from 'react-native/Libraries/Types/CodegenTypes';
import { codegenNativeComponent } from 'react-native';

export interface NativeProps extends ViewProps {
  type?: WithDefault<'title' | 'left' | 'right', 'title'>;
}

export default codegenNativeComponent<NativeProps>('TrueSheetNavBarItem', {});
